sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/core/routing/History",
	"sap/ui/Device",
    'sap/ui/model/json/JSONModel'
],
    /**
     * @param {typeof sap.ui.core.mvc.Controller} Controller
     */
    function (Controller,History,Device,JSONModel) {
        "use strict";

        return Controller.extend("project1.controller.View1", {

            onInit : function () {

            // set explored app's demo model on this sample
			//var oModel = new JSONModel("/model/data.json");
            var oModel = this.getOwnerComponent().getModel("myJsonData");
            //this.getView().setModel(oModel, "myModel");
			this.getView().setModel(oModel,'order');
            this.getOwnerComponent().getRouter().getRoute("master").attachPatternMatched(this._onRouteMatched, this);

            },
            _onRouteMatched: function(oEvent) {
                /*
                * Navigate to the first item by default only on desktop and tablet (but not phone). 
                * Note that item selection is not handled as it is
                * out of scope of this sample
                */

                    this.getOwnerComponent().getRouter()
                        .navTo("orderDetails", true);			
                
            },
            onSelectionChange: function(oEvent) {
                var sOrderId = oEvent.getSource().getSelectedItem().getProperty("intro");
                this.getOwnerComponent().getRouter()
                    .navTo("orderDetails", 
                        {orderId:sOrderId}, 
                        !Device.system.phone);
            }
    
        });
    });
