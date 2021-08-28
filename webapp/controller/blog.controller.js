sap.ui.define([
    "sap/m/library",
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
    "sap/m/Text",
    "sap/ui/core/routing/History"
],
	/**
	 * @param {typeof sap.ui.core.mvc.Controller} Controller
	 */
    function (mobileLibrary, Controller, MessageBox, MessageToast, JSONModel, Fragment, ValueState, Dialog, DialogType, Button, ButtonType, Text, History) {
        "use strict";

        var URLHelper = mobileLibrary.URLHelper;

        return Controller.extend("pro.proj.controller.blog", {
            onInit: function () {

                var oRouter = sap.ui.core.UIComponent.getRouterFor(this);
                oRouter.getRoute("RouteBlogsView").attachMatched(this._onRouteFound, this);

            },
            // Bind UI element from backend data 
            _onRouteFound: function (oEvent) {

                console.log(" BLOG VIEW"); // }
            },
            goBack: function (oEvent) {
                var oHistory, sPreviousHash;

                oHistory = History.getInstance();
                sPreviousHash = oHistory.getPreviousHash();

                if (sPreviousHash !== undefined) {
                    window.history.go(-1);
                } else {
                    this.getOwnerComponent().getRouter().navTo("RouteView", {}, true /*no history*/);
                }
            },



        });
    });
