// requires all files from the "crypt" directory

BS.Encrypt = {

  encryptData: function(data, publicKey) {
    BS.Crypto.rng_seed_time();

    var rsa = new BS.Crypto.RSAKey();
    rsa.setPublic(publicKey, "10001");

    var packSize = rsa.maxDataSize(data);
    var encrypted = [];
    for (var i=0; i<data.length; i+=packSize) {
      var endIdx = Math.min(data.length, i+packSize);
      var part = data.substring(i, endIdx);
      encrypted.push(rsa.encrypt(part));
    }

    return encrypted.join('');
  }

};