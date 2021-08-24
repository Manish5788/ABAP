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

                // set explored app's demo model on this sample
                var oModel = new JSONModel("model/EmployeeData.json");
                this.getView().setModel(oModel, "model");

                var oButton = oEvent.getSource(),
                    oView = this.getView();

                if (!this._pQuickView) {
                    this._pQuickView = Fragment.load({
                        id: oView.getId(),
                        name: "pro.proj.view.HelloDialog",
                        controller: this
                    }).then(function (oQuickView) {
                        oView.addDependent(oQuickView);
                        return oQuickView;
                    });
                }
                this._pQuickView.then(function (oQuickView) {
                    oQuickView.setModel(oModel);
                    oQuickView.openBy(oButton);
                });
            },
            onNavigate: function (oEvent) {
                MessageToast.show("E-Mail has been sent");
            }

        });
    });
