import ballerina/http;
import ballerina/graphql;


type User record {|
    readonly string id;
    string name;
    int age;
    string? phone = "";
    string? email = "";
|};

type OptionalUser record {|
    string? id = ();
    string? name = ();
    int? age = ();
    string? phone = ();
    string? email = ();
|};

final table<User> key(id) usersTable = table [
    {id: "1", name: "Alice", age: 34, email: "alice@test.com" },
    {id: "2", name: "Bob", age: 23, phone: "1234-56789" },
    {id: "3", name: "Charlie", age: 28 }
];

public distinct service class UserData {
    private final readonly & User userRecord;

    function init(User userRecord) {
        self.userRecord = userRecord.cloneReadOnly();
    }

    resource function get id() returns string => self.userRecord.id;
    resource function get name() returns string => self.userRecord.name;
    resource function get age() returns int? => self.userRecord.age;
    resource function get phone() returns string? => self.userRecord.phone;
    resource function get email() returns string? => self.userRecord.email;
}

//REST API
service / on new http:Listener(9090) {

    //REST Endpoints
    resource function get users() returns json|error {
        return usersTable.toJson();
    }

    //GET http://localhost:9090/users/123
    resource function get users/[string userId](http:Request req) returns http:Response|json|error {
        string customHeader = check req.getHeader("Content-Type");
        string|error customHeader2 = req.getHeader("X-Custom-Header");

        if !usersTable.hasKey(userId) {
            http:Response response = new;
            response.statusCode = 404;
            response.setJsonPayload({ message: "Not found" }); 
            return response;
        }
        
        json response = {
            customHeader,
            customHeader2: customHeader2 is string ? customHeader2 : "",
            user: usersTable.get(userId)
        };
        return response;
    }

    //POST http://localhost:9090/users/123
    resource function post users(@http:Payload User user) returns User|error {
        usersTable.add(user);
        return user;
    }

    //PUT http://localhost:9090/users/123
    resource function put users/[string userId](@http:Payload User user) returns User|http:Response|error {        
        http:Response response = new;
        if !usersTable.hasKey(userId) {
            response.statusCode = 404;
            response.setJsonPayload({ message: "Not found" }); 
            return response;
        }
        if usersTable.get(userId).id != userId {
            response.statusCode = 400;
            response.setJsonPayload({ message: "Bad Request" }); 
            return response;
        }

        usersTable.put(user);
        return user;
    }
}

// GRAPHQL
// To generate the schema, use bal graphql -i service.bal
service /users on new graphql:Listener(9091) {

    //There are two fields in the Query type and one field in the Mutation type in your
    //GraphQL service. The fields of the Query type are represented by the resource methods with the get
    //accessor in Ballerina, while the fields of the Mutation type are represented by the
    //remote methods in Ballerina.

    resource function get all() returns UserData[] {
        return from User entry in usersTable select new (entry);
    }

    resource function get filter(string id, string?[] fields) returns OptionalUser? {
        if !usersTable.hasKey(id) {
            return;
        }

        User user = usersTable.get(id);
        OptionalUser response = {};

        foreach string prop in user.keys() {
            if (prop != "id" && (fields.length() == 0 || fields.indexOf(prop) >= 0)) {
                response[prop] = user[prop];
            }
        }
        return response;
    }

    //Define the Mutation type using remote methods
    remote function add(User entry) returns UserData {
        usersTable.add(entry);
        return new UserData(entry);
    }
}



