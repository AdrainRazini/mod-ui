import ADN from "./app.js";

const Cache = {

  set(key,value){
    localStorage.setItem(key, JSON.stringify(value));
  },

  get(key){
    const v = localStorage.getItem(key);
    return v ? JSON.parse(v) : null;
  },

  update(key, field, value){

    const data = this.get(key) || {};

    data[field] = value;

    this.set(key, data);

  },

  remove(key){
    localStorage.removeItem(key);
  },

  clear(){
    localStorage.clear();
  }

};

ADN.cache = Cache // Salva em App (Adn)
ADN["App"] = {};

//Cache.set("etiqueta",{})
//Cache.clear()
//console.log(ADN);
