import ballerina/io;
import ballerina/http;

// public function main() returns error? {
//     string ediMultipleText = check io:fileReadString("resources/MSCONS_ExampleMultipleTS.edi");
//     Metered_services_consumption_report_message mscons = check fromEdiString(ediMultipleText);
//     io:println(mscons.toJsonString());

//     string ediText = check io:fileReadString("resources/MSCONS_Example_SingleTS.edi");
//     Metered_services_consumption_report_message mscons_single = check fromEdiString(ediText);
//     io:println(mscons_single.toJsonString());
// }

service / on new http:Listener(5050) {
    resource function get convertedEDI(string ediFileName) returns string|error? {
        string ediMultipleText = check io:fileReadString("resources/" + ediFileName);
        Metered_services_consumption_report_message mscons = check fromEdiString(ediMultipleText);
        return mscons.toJsonString();
    }
}