let event;
let RequestFn;
let csrfmiddlewaretoken;

$(document).ready(function () {
    csrfmiddlewaretoken = $('input[name ="csrfmiddlewaretoken"]').val();
});

String.prototype.replaceAll = function (search, replacement) {
    let target = this;
    return target.replace(new RegExp(search, 'g'), replacement);
}

String.prototype.capitalize = function () {
    let target = this;
    return target.charAt(0).toUpperCase() + target.slice(1);
}

function beforeAjaxSend(xhr) {
    xhr.setRequestHeader('X-CSRFToken', csrfmiddlewaretoken);
}

/**
 * Clone object
 *
 * @param obj
 * @returns {*}
 */
function cloneObject(obj) {
    if (obj === null || typeof obj !== 'object') {
        return obj;
    }

    let temp = obj.constructor(); // give temp the original obj's constructor
    for (let key in obj) {
        temp[key] = cloneObject(obj[key]);
    }

    return temp;
}

function toCurrency(value, currency) {
    return Intl.NumberFormat('en-EN', { style: 'currency', currency: 'USD' }).format(value)
}

function capitalize(string) {
    //check if it is already has upper case
    string = string.replaceAll('_', ' ')
    if (/[A-Z]/.test(string)) {
        return string;
    }
    return string.charAt(0).toUpperCase() + string.slice(1);
}

function getRandomColor() {
    var letters = '0123456789ABCDEF';
    var color = '#';
    for (var i = 0; i < 6; i++) {
        color += letters[Math.floor(Math.random() * 16)];
    }
    return color;
}

const COLOURS = [
    "rgb(255, 99, 132)", "rgb(255, 159, 64)", "rgb(255, 205, 86)", "rgb(75, 192, 192)",
    "rgb(54, 162, 235)", "rgb(153, 102, 255)", "rgb(201, 203, 207)"
]

function colors(size) {
    return COLOURS.slice(0, size)
}

function cloneObject(obj) {
    if (obj === null || typeof obj !== 'object') {
        return obj;
    }

    var temp = obj.constructor(); // give temp the original obj's constructor
    for (var key in obj) {
        temp[key] = cloneObject(obj[key]);
    }

    return temp;
}

function setCookie(name, value, days) {
    var expires = "";
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + (value || "") + expires + "; path=/";
}

function getCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length, c.length);
    }
    return null;
}

function numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Todo: LIT
//  Change this to use database
//  Legend for graph
let bySubClassLegend = {};

/**
 * JSON TO PARAMS
 */
function jsonToUrlParams(object) {
  const params = []
  for (const [key, value] of Object.entries(object)) {
    params.push(`${key}=${value}`)
  }
  return params.join('&')
}