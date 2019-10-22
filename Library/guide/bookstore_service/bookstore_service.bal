import ballerina/log;
import ballerina/http;
import ballerina/jms;
import ballerina/io;
//import ballerina/json;
//import ballerina/internal;


type bookIssue record {
    string customerName?;
    string contactNumber?;
    string IssuedBookName?;
};

json[] bookInventory = ["Tom Jones", "The Rainbow", "Lolita", "Atonement", "Hamlet"];

jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

jms:QueueSender jmsProducer = new(jmsSession, queueName = "IssueQueue");

listener jms:QueueReceiver jmsConsumer = new(jmsSession, queueName = "ReturnQueue");

listener http:Listener httpListener = new(9090);

@http:ServiceConfig { basePath: "/bookstore" }
service bookstoreService on httpListener {
    // Resource that allows users to place an order for a book
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function IssueBook(http:Caller caller, http:Request request) {
        http:Response response = new;
        bookIssue newIssue = {};
        json reqPayload = ();

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is json) {
            // Valid JSON payload
            reqPayload = payload;
        } else {
            // Not a valid JSON payload
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
            return;
        }

        json name = reqPayload.Name;
        //json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json bookName = reqPayload.BookName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || contact == null || bookName == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
            return;
        }

        // Order details
        newIssue.customerName = name.toString();
        //newOrder.address = address.toString();
        newIssue.contactNumber = contact.toString();
        newIssue.IssuedBookName = bookName.toString();

        // boolean variable to track the availability of a requested book
        boolean isBookAvailable = false;
        // Check whether the requested book is available
        //int a=bookInventory.length();
        //a=a-1;
        json[] temp=[];
        int count=0;
        foreach var book in bookInventory {
            
            if (newIssue.IssuedBookName.equalsIgnoreCase(book.toString())) {
                isBookAvailable = true;
                //break;
            }
            else{
                temp[count]=book;
                count=count+1;
            }
        }

        json responseMessage = ();
        // If the requested book is available, then add the order to the 'OrderQueue'
        if (isBookAvailable) {
            var bookOrderDetails = json.convert(newIssue);
            // Create a JMS message
            if (bookOrderDetails is json) {
                var queueMessage = jmsSession.createTextMessage(bookOrderDetails.toString());
                if (queueMessage is jms:Message) {
                    // Send the message to the JMS queue
                    var result = jmsProducer->send(queueMessage);
                    if (result is error) {
                        log:printError("Error sending the message", err = result);
                    }
                    // Construct a success message for the response
                    responseMessage = { "Message": "Book successfully issued."
                             };
                    log:printInfo("Book issued to, CustomerName: '"
                            + newIssue.customerName + "', IssuedBook: '"
                            + newIssue.IssuedBookName + "';");
                }
            }
            bookInventory=temp;
        }
        else {
            // If book is not available, construct a proper response message to notify user
            responseMessage = { "Message": "Requested book not available" };
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
 @http:ResourceConfig {
        methods: ["GET"],
        produces: ["application/json"]
    }
    resource function getBookList(http:Caller caller, http:Request request) {
        http:Response response = new;
        // Send json array 'bookInventory' as the response, which contains all the available books
        response.setJsonPayload(bookInventory);
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}
//function closeRc(io:ReadableCharacterChannel rc) {
  //  var result = rc.close();
    //if (result is error) {
     //   log:printError("Error occurred while closing character stream",
                    //    err = result);
   // }
//}
//function read(string path) returns json|error {
//
 //   io:ReadableByteChannel rbc = io:openReadableFile(path);

  //  io:ReadableCharacterChannel rch = new(rbc, "UTF8");
  //  var result = rch.readJson();
  //  if (result is error) {
   //     closeRc(rch);
   //     return result;
  //  } else {
    //    closeRc(rch);
   //     return result;
   // }
//}

service orderDeliverySystem on jmsConsumer {
    // Triggered whenever an order is added to the 'OrderQueue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("Book returned thruogh the JMS Queue");
        // Retrieve the string payload using native function
        var stringPayload = message.getTextMessageContent();
       if (stringPayload is string) {
            int flag=0;
   //         //string str = stringPayload;
            //io:StringReader sr = new(str, encoding = "UTF-8");
   //         if(stringPayload==""){
   // }
   // else{
            //var rResult = read(stringPayload);
            
       // if (rResult is error) {
         //   log:printError("Error occurred while reading json: ",
           //                 err = rResult);
        //} else {
        //    io:println(rResult);
        //    bookName=rResult;
       // }
           // io:println(j);
         //  json j = <json> stringPayload ;
          //  io:println(j);
          io:StringReader reader = new io:StringReader(stringPayload);
        var result = reader.readJson();
        if (result is json) {
        //bmap[result.bookId.toString()]=result.bookName.toString();
    
        json j= result.returnedBookName;
        io:println(j);
            foreach var book in bookInventory {
                flag=flag+1;
            }
            //flag=flag+1
            //if (j is json){
          //      io:println(j);
          //  json bookName=j["returnedBookName"];
            string a= j.toString();
          //  io:println(bookName);
           bookInventory[flag]=a; 
   // }
     //    else {
       //     log:printInfo("Error occurred while returning the book");
       // }
    }
        }
    }
}