import ballerina/log;
import ballerina/http;
import ballerina/jms;
import ballerina/io;

type bookReturn record {
    string customerName?;
    //string contactNumber?;
    string returnedBookName?;
};

jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

jms:QueueSender jmsProducer = new(jmsSession, queueName = "ReturnQueue");

listener http:Listener httpListener = new(11002);

@http:ServiceConfig { basePath: "/bookstore" }
service bookstoreService on httpListener {
    // Resource that allows users to place an order for a book
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }

    resource function returnBook(http:Caller caller, http:Request request) {
        http:Response response = new;
        bookReturn book = {};
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
        //json contact = reqPayload.ContactNumber;
        json bookName = reqPayload.returnedBookName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (bookName == null || name == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
            return;
        }

        // Order details
        book.customerName = name.toString();
        //newOrder.address = address.toString();
        //newOrder.contactNumber = contact.toString();
        book.returnedBookName = bookName.toString();

        // boolean variable to track the availability of a requested book
     //   boolean isBookAvailable = false;
    //    // Check whether the requested book is available
    //    foreach var book in bookInventory {
      //      if (newOrder.orderedBookName.equalsIgnoreCase(book.toString())) {
    //            isBookAvailable = true;
     //           break;
    //        }
    //    }

        json responseMessage = ();
        // If the requested book is available, then add the order to the 'OrderQueue'
    //    if (isBookAvailable) {
            var bookOrderDetails = json.convert(book);
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
                    responseMessage = { "Message": "book returned successfully"
                             };
                    log:printInfo("book returned to the JMS Queue, and BookName: '"
                            + book.returnedBookName + "';");
                }
            }
    //    }
    //    else {
            // If book is not available, construct a proper response message to notify user
    //        responseMessage = { "Message": "Requested book not available" };
    //    }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}


