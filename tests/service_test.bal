import ballerina/io;
import ballerina/http;
import ballerina/test;

http:Client testClient = check new ("http://localhost:9090");

// Before Suite Function

@test:BeforeSuite
function beforeSuiteFunc() {
    io:println("I'm the before suite function!");
}

// Test function

@test:Config {}
function testGetUsers() returns error? {
    // Define the expected JSON response
    json expectedResponse = [
        {id: "1", name: "Alice", age: 34, email: "alice@test.com", phone: ""},
        {id: "2", name: "Bob", age: 23, email: "", phone: "1234-56789"},
        {id: "3", name: "Charlie", age: 28, email: "", phone: ""}
    ];

    // Create a client to send a request to the service
    http:Client clientEP = check new ("http://localhost:9090");

    // Send a GET request to the /users endpoint
    http:Response response = check clientEP->get("/users");

    // Get the JSON payload from the response
    json jsonResponse = check response.getJsonPayload();

    // Assert that the response JSON matches the expected JSON
    test:assertEquals(jsonResponse, expectedResponse, msg = "Response JSON does not match the expected JSON.");
}

@test:Config {}
function testGetUserNotFound() returns error? {

    http:Client clientEP = check new ("http://localhost:9090");
    http:Response response = check clientEP->get("/users/12345", { "Content-Type": "application/json" });
    test:assertEquals(response.statusCode, 404, msg = "Response should be 404");
}

@test:Config {}
function testGetUser() returns error? {

    http:Client clientEP = check new ("http://localhost:9090");
    http:Response response = check clientEP->get("/users/1", { "Content-Type": "application/json" });
    test:assertEquals(response.statusCode, 200, msg = "Response should be 200");
}

@test:Config {}
function testPostUsers() returns error? {
    // Create a new user to be added
    User newUser = {
        id: "4",
        name: "Dave",
        age: 40,
        email: "dave@test.com"
    };

    // Expected JSON response after adding the new user
    json expectedResponse = {
        id: "4",
        name: "Dave",
        age: 40,
        phone:"",
        email: "dave@test.com"
    };

    // Create a client to send a request to the service
    http:Client clientEP = check new ("http://localhost:9090");

    // Send a POST request to the /users endpoint with the new user as payload
    http:Response response = check clientEP->post("/users", newUser);

    // Get the JSON payload from the response
    json jsonResponse = check response.getJsonPayload();

    // Assert that the response JSON matches the expected JSON
    test:assertEquals(jsonResponse, expectedResponse, msg = "Response JSON does not match the expected JSON.");

    // Verify that the user has been added to the usersTable
    http:Response getResponse = check clientEP->get("/users");
    json getJsonResponse = check getResponse.getJsonPayload();

    json expectedUsersTable = [
        {id: "1", name: "Alice", age: 34, email: "alice@test.com", phone: ""},
        {id: "2", name: "Bob", age: 23, email: "", phone: "1234-56789"},
        {id: "3", name: "Charlie", age: 28, email: "", phone: ""},
        {id: "4", name: "Dave", age: 40, email: "dave@test.com", phone: "" }
    ];

    test:assertEquals(getJsonResponse, expectedUsersTable, msg = "Users table does not match the expected state after adding new user.");
}


// After Suite Function

@test:AfterSuite
function afterSuiteFunc() {
    io:println("I'm the after suite function!");
}
