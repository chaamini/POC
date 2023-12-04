import ballerina/ftp;
import ballerina/http;
import ballerina/io;
import ballerina/lang.'string as strings;

configurable string host = ?;
configurable string username = ?;
configurable string password = ?;
configurable int port = ?;

ftp:ClientConfiguration ftpConfig = {
        protocol: ftp:SFTP,
        host: host,
        port: port,
        auth: {credentials: {username: username, password: password}}
};

ftp:Client clientEp = check new(ftpConfig);


service /processEDI on new http:Listener(5050) {
    resource function get .(string edifilePath) returns json|error? {
      string ediMultipleText = check readFile(edifilePath);
      Metered_services_consumption_report_message mscons = check fromEdiString(ediMultipleText);
      return mscons.toJsonString();
    }
}

function readFile(string filePath) returns string|error {
    stream<byte[] & readonly, io:Error?> str = check clientEp -> get("/voluepoc/EDIFiles/" + filePath);
    string fileContent = "";
    record {|byte[] value;|}|io:Error? bArray = str.next();
    if (bArray is record {|byte[] value;|}) {
        fileContent = check strings:fromBytes(bArray.value);
    }
    io:Error? closeResult = str.close();
    if (closeResult is io:Error) {
        io:println("Error while closing stream in `get` operation.");
    }
    return fileContent;
}
