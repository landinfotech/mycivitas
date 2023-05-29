/**
 * HTTP Request object
 */
define([
    'backbone',
    'jquery'], function (Backbone, $) {
    return Backbone.View.extend({
        /**
         * GET Request that receive url and handle callback
         * @param url
         * @param parameters, put parameter as json
         * @param headers, put header as json
         * @param successCallback, function when success
         * @param errorCallback, function when failed
         * @returns ajax
         */
        get: function (url, parameters, headers, successCallback, errorCallback) {
            return $.ajax({
                url: url,
                data: parameters,
                dataType: 'json',
                beforeSend: function (xhrObj) {
                    if (headers) {
                        $.each(headers, function (key, value) {
                            xhrObj.setRequestHeader(key, value);
                        });
                    }
                },
                success: function (data, textStatus, request) {
                    if (successCallback) {
                        successCallback(data, textStatus, request);
                    }
                },
                error: function (error, textStatus, request) {
                    if (errorCallback) {
                        errorCallback(error, textStatus, request)
                    }
                }
            });
        },
        /**
         * POST Request that receive url and handle callback
         * @param url
         * @param data, put data as json
         * @param successCallback, function when success
         * @param errorCallback, function when failed
         * @returns ajax
         */
        post: function (url, data, successCallback, errorCallback) {
            return $.ajax({
                url: url,
                data: data,
                dataType: 'json',
                type: 'POST',
                success: function (data, textStatus, request) {
                    if (successCallback) {
                        successCallback(data, textStatus, request);
                    }
                },
                error: function (error, textStatus, request) {
                    if (errorCallback) {
                        errorCallback(error, textStatus, request)
                    }
                },
                beforeSend: beforeAjaxSend
            });
        },
        /**
         * DELETE Request that receive url and handle callback
         * @param url
         * @param parameters, put parameter as json
         * @param successCallback, function when success
         * @param errorCallback, function when failed
         * @returns ajax
         */
        delete: function (url, parameters, successCallback, errorCallback) {
            /** DELETE Request that receive url and handle callback **/
            return $.ajax({
                url: url,
                data: parameters,
                dataType: 'json',
                type: 'DELETE',
                success: function (data, textStatus, request) {
                    if (successCallback) {
                        successCallback(data, textStatus, request);
                    }
                },
                error: function (error, textStatus, request) {
                    if (errorCallback) {
                        errorCallback(error, textStatus, request)
                    }
                },
                beforeSend: beforeAjaxSend
            });
        },
        /**
         * PATCH Request that receive url and handle callback
         * @param url
         * @param data, data as json
         * @param successCallback, function when success
         * @param errorCallback, function when failed
         * @returns ajax
         */
        patch: function (url, data, successCallback, errorCallback) {
            /** DELETE Request that receive url and handle callback **/
            return $.ajax({
                url: url,
                data: data,
                dataType: 'json',
                type: 'PATCH',
                success: function (data, textStatus, request) {
                    if (successCallback) {
                        successCallback(data, textStatus, request);
                    }
                },
                error: function (error, textStatus, request) {
                    if (errorCallback) {
                        errorCallback(error, textStatus, request)
                    }
                },
                beforeSend: beforeAjaxSend
            });
        },
        promiseGet: function (url, parameters, headers) {
            const that = this;
            return new Promise(function(resolve, reject) {
                that.get(
                    url, parameters, headers,
                    function (response) {
                        resolve(response)
                    },
                    function (error) {
                        reject(error)
                    }
                )
            });
        }
    })
});

