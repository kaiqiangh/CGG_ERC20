const { BigNumber } = require("bignumber.js");

BigNumber.config({ ROUNDING_MODE: BigNumber.ROUND_DOWN });
BigNumber.config({ EXPONENTIAL_AT: 100 });
const _charStr = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
function toBN (value){
    const valueString = typeof value === "string" ? value : String(value);
    return new BigNumber(valueString);
};

function accMul(arg1, arg2) {
    if (!arg1) {
        arg1 = 0;
    }
    if (!arg2) {
        arg2 = 0;
    }
    var m = 0, s1 = arg1.toString(), s2 = arg2.toString();
    try {
        m += s1.split(".")[1].length;
    } catch (e) {
    }
    try {
        m += s2.split(".")[1].length;
    } catch (e) {
    }
    var v1 = new BigNumber(Number(s1.replace(".", "")).toString());
    var v2 = new BigNumber(Number(s2.replace(".", "")).toString());
    var v3 = Math.pow(10, m);
    var v4 = new BigNumber((v2 / v3).toString());
    return new BigNumber((v1 * v4).toString()) + "";
};

function getRandomString(length) {
    const characters ='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result1= ' ';
    const charactersLength = characters.length;
    for ( let i = 0; i < length; i++ ) {
        result1 += characters.charAt(Math.floor(Math.random() * charactersLength));
    }

    return result1;
}

module.exports = {
    MAX_UINT_256 : new BigNumber(2).pow(256).minus(1),
    toBN,
    accMul,
    getRandomString
}
