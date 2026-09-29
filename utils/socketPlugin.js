const { getIO } = require('./socket');

module.exports = function socketPlugin(schema, options) {
  const emitChange = (modelName, operation) => {
    try {
      const io = getIO();
      if (io && modelName) {
        io.emit('data_updated', {
          model: modelName,
          operation: operation,
          timestamp: new Date()
        });
      }
    } catch (err) {
      // Ignore if socket not initialized
    }
  };

  schema.post('save', function(doc) {
    const modelName = doc && doc.constructor ? doc.constructor.modelName : null;
    emitChange(modelName, 'save');
  });

  schema.post('findOneAndDelete', function(doc) {
    const modelName = doc && doc.constructor ? doc.constructor.modelName : null;
    emitChange(modelName, 'delete');
  });

  schema.post('findOneAndUpdate', function(doc) {
    const modelName = doc && doc.constructor ? doc.constructor.modelName : null;
    emitChange(modelName, 'update');
  });

  schema.post('updateOne', function() {
    if (this.model) {
      emitChange(this.model.modelName, 'update');
    }
  });

  schema.post('updateMany', function() {
    if (this.model) {
      emitChange(this.model.modelName, 'update');
    }
  });
  
  schema.post('deleteOne', function() {
    if (this.model) {
      emitChange(this.model.modelName, 'delete');
    }
  });
  
  schema.post('deleteMany', function() {
    if (this.model) {
      emitChange(this.model.modelName, 'delete');
    }
  });
};
