const mongoose = require('mongoose');
const { ObjectId } = mongoose.Types;

const c = {
  categoryId: new ObjectId('69fb205aa54c4530043575b8')
};
console.log(c.categoryId.toString());
