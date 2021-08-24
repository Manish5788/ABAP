sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageBox",
    "sap/m/MessageToast",
    "sap/ui/model/json/JSONModel",
    "sap/ui/core/Fragment"
],
	/**
	 * @param {typeof sap.ui.core.mvc.Controller} Controller
	 */
    function (Controller, MessageBox, MessageToast, JSONModel, Fragment) {
        "use strict";

        return Controller.extend("pro.proj.controller.View", {
            onInit: function () {

            },

            handlePopoverPress: function (oEvent) {
                MessageBox.information("Execute Order 66");

            },
            handleQuickViewPress: function (oEvent) {
                MessageBox.information("Execute Order Yahan contact aayega");

            }



        });
    });
