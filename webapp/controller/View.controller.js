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
                var oEmployeeModel = new JSONModel(sap.ui.require.toUrl("model/EmployeeData.json"));

                this.getView().setModel(oEmployeeModel, "EmployeeModel")
            },

            onAfterRendering: function () {

                var oButton = this.byId("employeeQuickView");
                oButton.$().attr("aria-haspopup", true);

            },
            handlePopoverPress: function (oEvent) {
                MessageBox.information("Execute Order 66");

            },
            handleEmployeeQuickViewPress: function (oEvent) {
                var oModel = this.getView().getModel("EmployeeModel");
                 MessageToast.show("contact button was clicked");
            },
            onNavigate: function (oEvent) {
                var oNavOrigin = oEvent.getParameter("navOrigin");
                if (oNavOrigin) {
                    MessageToast.show("Link '" + oNavOrigin.getText() + "' was clicked");
                } else {
                    MessageToast.show("Back button was clicked");
                }
            },
            onAvatarPressed: function () {
                MessageToast.show("Avatar pressed!");
            }


        });
    });
