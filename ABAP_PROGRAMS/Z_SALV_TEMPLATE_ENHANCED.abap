*&---------------------------------------------------------------------*
*& Report Z_SALV_TEMPLATE_ENHANCED
*&---------------------------------------------------------------------*
*& Purpose: Enhanced SALV Template with Event Handling & Custom Buttons
*& Author:  [Your Name]
*& Date:    [Current Date]
*& Description: Advanced SALV template with event handling, custom
*&              toolbar buttons, hotspot functionality, and context menu
*&---------------------------------------------------------------------*

REPORT z_salv_template_enhanced.

*----------------------------------------------------------------------*
* Class Definition for Event Handling
*----------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: on_link_click FOR EVENT link_click OF cl_salv_events_table
                           IMPORTING row column,
             on_double_click FOR EVENT double_click OF cl_salv_events_table
                             IMPORTING row column,
             on_added_function FOR EVENT added_function OF cl_salv_events
                               IMPORTING e_salv_function,
             on_before_salv_function FOR EVENT before_salv_function OF cl_salv_events
                                     IMPORTING e_salv_function.
ENDCLASS.

*----------------------------------------------------------------------*
* Type Definitions
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_output,
         matnr TYPE mara-matnr,        " Material Number
         maktx TYPE makt-maktx,        " Material Description
         mtart TYPE mara-mtart,        " Material Type
         matkl TYPE mara-matkl,        " Material Group
         meins TYPE mara-meins,        " Base Unit
         ersda TYPE mara-ersda,        " Created On
         ernam TYPE mara-ernam,        " Created By
         laeda TYPE mara-laeda,        " Changed On
         aenam TYPE mara-aenam,        " Changed By
         lvorm TYPE mara-lvorm,        " Deletion Flag
         status TYPE icon-id,          " Status Icon
       END OF ty_output.

*----------------------------------------------------------------------*
* Internal Tables & Work Areas
*----------------------------------------------------------------------*
DATA: gt_output TYPE TABLE OF ty_output,
      gs_output TYPE ty_output.

*----------------------------------------------------------------------*
* SALV Objects
*----------------------------------------------------------------------*
DATA: go_alv       TYPE REF TO cl_salv_table,
      go_functions TYPE REF TO cl_salv_functions_list,
      go_display   TYPE REF TO cl_salv_display_settings,
      go_columns   TYPE REF TO cl_salv_columns_table,
      go_column    TYPE REF TO cl_salv_column_table,
      go_events    TYPE REF TO cl_salv_events_table,
      go_sorts     TYPE REF TO cl_salv_sorts,
      go_filters   TYPE REF TO cl_salv_filters,
      go_layout    TYPE REF TO cl_salv_layout,
      go_key       TYPE REF TO salv_s_layout_key,
      go_toolbar   TYPE REF TO cl_salv_functions_list.

*----------------------------------------------------------------------*
* Event Handler Instance
*----------------------------------------------------------------------*
DATA: go_event_handler TYPE REF TO lcl_event_handler.

*----------------------------------------------------------------------*
* Constants for Custom Functions
*----------------------------------------------------------------------*
CONSTANTS: c_refresh      TYPE salv_de_function VALUE 'REFRESH',
           c_export_excel TYPE salv_de_function VALUE 'EXPORT_EXCEL',
           c_show_details TYPE salv_de_function VALUE 'SHOW_DETAILS',
           c_toggle_edit  TYPE salv_de_function VALUE 'TOGGLE_EDIT'.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_matnr FOR mara-matnr,
                  s_mtart FOR mara-mtart,
                  s_matkl FOR mara-matkl,
                  s_ersda FOR mara-ersda.
  PARAMETERS: p_maxrow TYPE i DEFAULT 100.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_zebra  AS CHECKBOX DEFAULT 'X',
              p_layout AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
* Initialization
*----------------------------------------------------------------------*
INITIALIZATION.
  " Set default values
  s_ersda-sign   = 'I'.
  s_ersda-option = 'BT'.
  s_ersda-low    = sy-datum - 365.
  s_ersda-high   = sy-datum.
  APPEND s_ersda.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM get_data.
  IF NOT gt_output IS INITIAL.
    PERFORM display_alv.
  ENDIF.

*----------------------------------------------------------------------*
* Form: GET_DATA
*----------------------------------------------------------------------*
FORM get_data.
  " Select data from database
  SELECT m~matnr,
         t~maktx,
         m~mtart,
         m~matkl,
         m~meins,
         m~ersda,
         m~ernam,
         m~laeda,
         m~aenam,
         m~lvorm
    FROM mara AS m
    LEFT JOIN makt AS t ON m~matnr = t~matnr
                       AND t~spras = sy-langu
    INTO CORRESPONDING FIELDS OF TABLE gt_output
    WHERE m~matnr IN s_matnr
      AND m~mtart IN s_mtart
      AND m~matkl IN s_matkl
      AND m~ersda IN s_ersda
    UP TO p_maxrow ROWS.

  " Check if data was found
  IF gt_output IS INITIAL.
    MESSAGE i001(z_custom) WITH 'No data found for the given selection criteria'.
    RETURN.
  ENDIF.

  " Add status icons and process data
  PERFORM process_data.

  " Sort data by material number
  SORT gt_output BY matnr.
ENDFORM.

*----------------------------------------------------------------------*
* Form: PROCESS_DATA
*----------------------------------------------------------------------*
FORM process_data.
  LOOP AT gt_output INTO gs_output.
    " Add status icon based on deletion flag
    IF gs_output-lvorm IS NOT INITIAL.
      gs_output-status = icon_red_light.
    ELSE.
      gs_output-status = icon_green_light.
    ENDIF.
    MODIFY gt_output FROM gs_output.
  ENDLOOP.
ENDFORM.

*----------------------------------------------------------------------*
* Form: DISPLAY_ALV
*----------------------------------------------------------------------*
FORM display_alv.
  TRY.
      " Create SALV instance
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_alv
        CHANGING
          t_table      = gt_output ).

      " Get objects
      go_functions = go_alv->get_functions( ).
      go_display   = go_alv->get_display_settings( ).
      go_columns   = go_alv->get_columns( ).
      go_events    = go_alv->get_event( ).
      go_sorts     = go_alv->get_sorts( ).
      go_filters   = go_alv->get_filters( ).
      go_layout    = go_alv->get_layout( ).

      " Configure ALV
      PERFORM configure_alv.

      " Setup event handling
      PERFORM setup_event_handling.

      " Add custom toolbar buttons
      PERFORM add_custom_functions.

      " Display ALV
      go_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv_msg).
      MESSAGE lx_salv_msg->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

*----------------------------------------------------------------------*
* Form: CONFIGURE_ALV
*----------------------------------------------------------------------*
FORM configure_alv.
  " Enable standard functions
  go_functions->set_all( ).

  " Set display settings
  IF p_zebra = 'X'.
    go_display->set_striped_pattern( cl_salv_display_settings=>true ).
  ENDIF.
  go_display->set_list_header( 'Enhanced Material Master Data - SALV Template' ).

  " Configure columns
  PERFORM setup_columns.

  " Set default sorting
  PERFORM setup_sorting.

  " Set layout
  IF p_layout = 'X'.
    PERFORM setup_layout.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form: SETUP_COLUMNS
*----------------------------------------------------------------------*
FORM setup_columns.
  " Optimize column width
  go_columns->set_optimize( ).

  TRY.
      " Status Icon
      go_column ?= go_columns->get_column( 'STATUS' ).
      go_column->set_long_text( 'Status' ).
      go_column->set_medium_text( 'Status' ).
      go_column->set_short_text( 'Stat' ).
      go_column->set_icon( if_salv_c_bool_sap=>true ).

      " Material Number - with hotspot
      go_column ?= go_columns->get_column( 'MATNR' ).
      go_column->set_long_text( 'Material Number' ).
      go_column->set_medium_text( 'Material No.' ).
      go_column->set_short_text( 'Mat.No.' ).
      go_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

      " Material Description
      go_column ?= go_columns->get_column( 'MAKTX' ).
      go_column->set_long_text( 'Material Description' ).
      go_column->set_medium_text( 'Description' ).
      go_column->set_short_text( 'Desc.' ).

      " Material Type
      go_column ?= go_columns->get_column( 'MTART' ).
      go_column->set_long_text( 'Material Type' ).
      go_column->set_medium_text( 'Mat. Type' ).
      go_column->set_short_text( 'Type' ).

      " Material Group
      go_column ?= go_columns->get_column( 'MATKL' ).
      go_column->set_long_text( 'Material Group' ).
      go_column->set_medium_text( 'Mat. Group' ).
      go_column->set_short_text( 'Group' ).

      " Base Unit
      go_column ?= go_columns->get_column( 'MEINS' ).
      go_column->set_long_text( 'Base Unit of Measure' ).
      go_column->set_medium_text( 'Base Unit' ).
      go_column->set_short_text( 'Unit' ).

      " Created On
      go_column ?= go_columns->get_column( 'ERSDA' ).
      go_column->set_long_text( 'Created On' ).
      go_column->set_medium_text( 'Created' ).
      go_column->set_short_text( 'Crtd' ).

      " Created By
      go_column ?= go_columns->get_column( 'ERNAM' ).
      go_column->set_long_text( 'Created By' ).
      go_column->set_medium_text( 'Created By' ).
      go_column->set_short_text( 'CrtBy' ).

      " Changed On
      go_column ?= go_columns->get_column( 'LAEDA' ).
      go_column->set_long_text( 'Last Changed On' ).
      go_column->set_medium_text( 'Changed' ).
      go_column->set_short_text( 'Chgd' ).

      " Changed By
      go_column ?= go_columns->get_column( 'AENAM' ).
      go_column->set_long_text( 'Last Changed By' ).
      go_column->set_medium_text( 'Changed By' ).
      go_column->set_short_text( 'ChgBy' ).

      " Deletion Flag
      go_column ?= go_columns->get_column( 'LVORM' ).
      go_column->set_long_text( 'Deletion Flag' ).
      go_column->set_medium_text( 'Del. Flag' ).
      go_column->set_short_text( 'Del' ).

    CATCH cx_salv_not_found.
      MESSAGE 'Column not found' TYPE 'I'.
  ENDTRY.
ENDFORM.

*----------------------------------------------------------------------*
* Form: SETUP_SORTING
*----------------------------------------------------------------------*
FORM setup_sorting.
  TRY.
      go_sorts->add_sort( columnname = 'MATNR'
                          position   = 1
                          sequence   = if_salv_c_sort=>c_sort_asc ).
    CATCH cx_salv_not_found
          cx_salv_existing
          cx_salv_data_error.
      MESSAGE 'Error setting up sorting' TYPE 'I'.
  ENDTRY.
ENDFORM.

*----------------------------------------------------------------------*
* Form: SETUP_LAYOUT
*----------------------------------------------------------------------*
FORM setup_layout.
  go_key = VALUE #( report = sy-repid ).
  go_layout->set_key( go_key ).
  go_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  go_layout->set_default( abap_true ).
ENDFORM.

*----------------------------------------------------------------------*
* Form: SETUP_EVENT_HANDLING
*----------------------------------------------------------------------*
FORM setup_event_handling.
  " Create event handler instance
  CREATE OBJECT go_event_handler.

  " Register events
  SET HANDLER go_event_handler->on_link_click FOR go_events.
  SET HANDLER go_event_handler->on_double_click FOR go_events.
  SET HANDLER go_event_handler->on_added_function FOR go_events.
  SET HANDLER go_event_handler->on_before_salv_function FOR go_events.
ENDFORM.

*----------------------------------------------------------------------*
* Form: ADD_CUSTOM_FUNCTIONS
*----------------------------------------------------------------------*
FORM add_custom_functions.
  TRY.
      " Add custom toolbar buttons
      go_functions->add_function(
        name     = c_refresh
        icon     = icon_refresh
        text     = 'Refresh Data'
        tooltip  = 'Refresh the data from database'
        position = if_salv_c_function_position=>right_of_salv_functions ).

      go_functions->add_function(
        name     = c_export_excel
        icon     = icon_xxl
        text     = 'Export to Excel'
        tooltip  = 'Export data to Excel file'
        position = if_salv_c_function_position=>right_of_salv_functions ).

      go_functions->add_function(
        name     = c_show_details
        icon     = icon_detail
        text     = 'Show Details'
        tooltip  = 'Show detailed information'
        position = if_salv_c_function_position=>right_of_salv_functions ).

    CATCH cx_salv_existing
          cx_salv_wrong_call.
      MESSAGE 'Error adding custom functions' TYPE 'I'.
  ENDTRY.
ENDFORM.

*----------------------------------------------------------------------*
* Class Implementation for Event Handling
*----------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_link_click.
    " Handle hotspot click (e.g., Material Number)
    READ TABLE gt_output INTO gs_output INDEX row.
    IF sy-subrc = 0.
      CASE column.
        WHEN 'MATNR'.
          MESSAGE i002(z_custom) WITH 'Material' gs_output-matnr 'clicked'.
          " Here you could call transaction MM03 or display details
          " CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
      ENDCASE.
    ENDIF.
  ENDMETHOD.

  METHOD on_double_click.
    " Handle double-click on any cell
    READ TABLE gt_output INTO gs_output INDEX row.
    IF sy-subrc = 0.
      MESSAGE i003(z_custom) WITH 'Double-clicked on row' row 'column' column.
      " Implement your double-click logic here
    ENDIF.
  ENDMETHOD.

  METHOD on_added_function.
    " Handle custom toolbar button clicks
    CASE e_salv_function.
      WHEN c_refresh.
        PERFORM refresh_data.
      WHEN c_export_excel.
        PERFORM export_to_excel.
      WHEN c_show_details.
        PERFORM show_details.
    ENDCASE.
  ENDMETHOD.

  METHOD on_before_salv_function.
    " Handle standard ALV functions if needed
    " This method is called before any standard ALV function is executed
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Form: REFRESH_DATA
*----------------------------------------------------------------------*
FORM refresh_data.
  " Clear current data
  CLEAR: gt_output.

  " Reload data
  PERFORM get_data.

  " Refresh ALV display
  go_alv->refresh( ).

  MESSAGE s004(z_custom) WITH 'Data refreshed successfully'.
ENDFORM.

*----------------------------------------------------------------------*
* Form: EXPORT_TO_EXCEL
*----------------------------------------------------------------------*
FORM export_to_excel.
  " Custom Excel export logic
  DATA: lo_writer TYPE REF TO cl_salv_export_excel.

  TRY.
      " Create Excel export object
      CREATE OBJECT lo_writer.

      " Export to Excel
      lo_writer->export_to_excel(
        ir_salv_table = go_alv
        iv_filename   = 'Material_Data.xlsx' ).

      MESSAGE s005(z_custom) WITH 'Data exported to Excel successfully'.

    CATCH cx_root INTO DATA(lx_error).
      MESSAGE lx_error->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

*----------------------------------------------------------------------*
* Form: SHOW_DETAILS
*----------------------------------------------------------------------*
FORM show_details.
  " Show additional details or statistics
  DATA: lv_count TYPE i,
        lv_text  TYPE string.

  DESCRIBE TABLE gt_output LINES lv_count.

  lv_text = |Total records: { lv_count }|.
  MESSAGE i006(z_custom) WITH lv_text.
ENDFORM.

*----------------------------------------------------------------------*
* Text Symbols
*----------------------------------------------------------------------*
* Selection texts:
* S_MATNR    Material Number
* S_MTART    Material Type
* S_MATKL    Material Group
* S_ERSDA    Created On
* P_MAXROW   Maximum Rows
* P_ZEBRA    Zebra Pattern
* P_LAYOUT   Save Layout

* Text symbols:
* 001    Selection Criteria
* 002    Display Options