class Message {
    constructor(userId, message) {
        this.userId = userId;
        this.message = message;
    }
}

let messages = {};

export function handleMessages(socket, roomName, message, io) {
    if (!messages[roomName]) messages[roomName] = [];
    
    messages[roomName].push(new Message(socket.id, message));

    io.to(roomName).emit("update_messages", messages[roomName]);
}
