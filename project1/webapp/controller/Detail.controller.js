sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/core/routing/History",
    "sap/ui/Device"

],
    /**
     * @param {typeof sap.ui.core.mvc.Controller} Controller
     */
    function (Controller,History,Device) {
        "use strict";

        return Controller.extend("project1.controller.Detail", {
            onInit : function () {

                var oModel = this.getOwnerComponent().getModel("myJsonData");
                this.getView().setModel(oModel, "myModel");
                this.getOwnerComponent().getRouter().getRoute("orderDetails").attachPatternMatched(this._onRouteMatched, this);
            },
            _onRouteMatched: function(oEvent) {
                // var oSelectedItem = oEvent.getSource();
                
			    // //var oContext = oSelectedItem.getBindingContext("order");

			    // var sPath = oContext.getPath();
                this._orderId = oEvent.getParameter("arguments").orderId;
                this.getView().bindElement({path: "/orders/" + this._orderId , model: "myModel"});
            }
            // onSelectionChange: function(oEvent) {
            //     var sProductId = oEvent.getSource().getBindingContext().getProperty("productId");
            //     this.getOwnerComponent().getRouter()
            //         .navTo("productDetails",
            //             {orderId:this._orderId, productId: sProductId});
            // },
            // onNavBack : function() {
            //     var sPreviousHash = History.getInstance().getPreviousHash();
            //     //The history contains a previous entry
            //     if (sPreviousHash !== undefined) {
            //         history.go(-1);
            //     } else {
            //         // There is no history!
            //         // Naviate to master page
            //         this.getOwnerComponent().getRouter().navTo("master", {}, true);
            //     }
            // }
        });
    });
