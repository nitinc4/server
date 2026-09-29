const socketIo = require('socket.io');

let io;

module.exports = {
  init: (httpServer) => {
    io = socketIo(httpServer, {
      cors: {
        origin: [
          'http://localhost:5173',
          'https://snbtradingco.in',
          'https://www.snbtradingco.in',
          'https://zudo-sellerpanel-final.vercel.app',
          'https://zudo-adminpanel.vercel.app'
        ],
        credentials: true
      }
    });
    return io;
  },
  getIO: () => {
    if (!io) {
      throw new Error('Socket.io not initialized!');
    }
    return io;
  }
};
