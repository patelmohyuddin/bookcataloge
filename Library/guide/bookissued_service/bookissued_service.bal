import ballerina/log;
import ballerina/jms;

// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conn = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session
listener jms:QueueReceiver jmsConsumer = new(jmsSession, queueName = "IssueQueue");

// JMS service that consumes messages from the JMS queue
// Attach service to the created JMS consumer
service orderDeliverySystem on jmsConsumer {
    // Triggered whenever an order is added to the 'OrderQueue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("Book issued thruogh the JMS Queue");
        // Retrieve the string payload using native function
        var stringPayload = message.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("Issued Book Details: " + stringPayload);
        } else {
            log:printInfo("Error occurred while retrieving the order details");
        }
    }
}
