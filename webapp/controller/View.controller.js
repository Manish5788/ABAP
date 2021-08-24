sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageBox",
    "sap/m/MessageToast",
    "sap/ui/model/json/JSONModel",
    "sap/ui/core/Fragment",
    "sap/ui/core/ValueState",
    "sap/m/Dialog",
    "sap/m/DialogType",
    "sap/m/Button",
    "sap/m/ButtonType",
    "sap/m/Text"
],
	/**
	 * @param {typeof sap.ui.core.mvc.Controller} Controller
	 */
    function (Controller, MessageBox, MessageToast, JSONModel, Fragment, ValueState, Dialog, DialogType, Button, ButtonType, Text) {
        "use strict";

        return Controller.extend("pro.proj.controller.View", {
            onInit: function () {

            },

            handlePopoverPress: function (oEvent) {
                MessageBox.information("Execute Order 66");

            },
            handleQuickViewPress: function (oEvent) {

                if (!this.oDefaultMessageDialog) {
                    this.oDefaultMessageDialog = new Dialog({
                        type: DialogType.Message,
                        title: "Contact Details",
                        content: new Text({ text: "Hello There , This is Manish" }),
                       
                        beginButton: new Button({
                            type: ButtonType.Emphasized,
                            text: "OK",
                            press: function () {
                                this.oDefaultMessageDialog.close();
                            }.bind(this)
                        }),
                        endButton: new Button({
                            text: "Cancel",
                            press: function () {
                                this.oDefaultMessageDialog.close();
                            }.bind(this)
                        })
                    });
                }
                this.oDefaultMessageDialog.open();

            }

        });
    });
