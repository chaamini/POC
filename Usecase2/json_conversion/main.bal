import ballerina/email;
import ballerina/file;
import ballerina/io;
import ballerina/log;
import ballerina/mime;
import ballerina/time;

type TurbineReading record {
    string Date;
    decimal Value;
};

configurable string host = ?;
configurable string username = ?;
configurable string password = ?;
configurable decimal pollingInterval = ?;

listener email:ImapListener emailListener = check new ({host, username, password, pollingInterval});

service "emailObserver" on emailListener {
    remote function onMessage(email:Message email) {

        mime:Entity[]? attachments = <mime:Entity[]?>email.attachments;
        if attachments is () {
            return;
        }
        foreach mime:Entity mEntity in attachments {
            do {
                json attachment = check mEntity.getJson();
                map<json> attachmentObj = check attachment.ensureType();
                map<json> dataObj = check attachmentObj.data.ensureType();
                foreach string turbineName in dataObj.keys() {
                    TurbineReading[] turbineReadings = check dataObj[turbineName].cloneWithType();
                    foreach TurbineReading reading in turbineReadings {
                        [string, string] [reqDateStartTime, reqDateStopTime] = check getStartStopTime(reading.Date);
                        xml output = xml `<DataPointValue><DateStart>${reqDateStartTime}</DateStart><DateStop>${reqDateStopTime}</DateStop><ValueInstance1><Value>${reading.Value}</Value><Quality>0</Quality></ValueInstance1></DataPointValue>`;
                        string timeFolderPath = check createOutputDirectory(reading.Date);
                        string xmlFileName = timeFolderPath.concat("/").concat(turbineName).concat(".xml");
                        _ = check io:fileWriteXml(xmlFileName, output);
                    }
                }
            } on fail var err {
                log:printError("Error while processing content: " + err.message());
                return;
            }
        }
    }

    remote function onError(email:Error emailError) {
        io:println("Error while polling for the emails: " + emailError.message());
    }

    remote function onClose(email:Error? closeError) {
        io:println("Closed the listener.");
    }
}

function createOutputDirectory(string dateStartTime) returns string|error {
    string timeFolderPath = check file:joinPath(file:getCurrentDir(), "/OutputFiles/", dateStartTime);
    boolean dirExists = check file:test(timeFolderPath, file:EXISTS);
    if dirExists == false {
        _ = check file:createDir(timeFolderPath, file:RECURSIVE);
    }
    return timeFolderPath;
}

function getStartStopTime(string startTime) returns [string, string]|error {
    string startTimeStr = string `${startTime.substring(0, 10)}T${startTime.substring(11, 25)}`;
    time:Utc utcStartTime = check time:utcFromString(startTimeStr);
    time:Utc utcStopTime = time:utcAddSeconds(utcStartTime, 3600);
    string stopTimeStr = time:utcToString(utcStopTime);
    return [formatOutputDate(startTimeStr), formatOutputDate(stopTimeStr)];
}

function formatOutputDate(string dateTime) returns string {
    return string `${dateTime.substring(8, 10)}.${dateTime.substring(5, 7)}.${dateTime.substring(0, 4)} ${dateTime.substring(11, 19)}`;
}
