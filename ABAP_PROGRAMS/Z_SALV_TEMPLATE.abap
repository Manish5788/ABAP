*&---------------------------------------------------------------------*
*& Report Z_SALV_TEMPLATE
*&---------------------------------------------------------------------*
*& Purpose: Template for SALV (SAP List Viewer) programs
*& Author:  [Your Name]
*& Date:    [Current Date]
*& Description: This template provides a foundation for creating SALV
*&              reports with common functionality like filtering,
*&              sorting, exporting, and custom toolbar buttons.
*&---------------------------------------------------------------------*

REPORT z_salv_template.

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
      go_key       TYPE REF TO salv_s_layout_key.

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

*----------------------------------------------------------------------*
* Initialization
*----------------------------------------------------------------------*
INITIALIZATION.
  " Set default values if needed
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
  PERFORM display_alv.

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
    INTO TABLE gt_output
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

  " Sort data by material number
  SORT gt_output BY matnr.
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

      " Get functions, display, columns objects
      go_functions = go_alv->get_functions( ).
      go_display   = go_alv->get_display_settings( ).
      go_columns   = go_alv->get_columns( ).
      go_events    = go_alv->get_event( ).
      go_sorts     = go_alv->get_sorts( ).
      go_filters   = go_alv->get_filters( ).
      go_layout    = go_alv->get_layout( ).

      " Configure ALV
      PERFORM configure_alv.

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
  " Enable all standard functions
  go_functions->set_all( ).

  " Set display settings
  go_display->set_striped_pattern( cl_salv_display_settings=>true ).
  go_display->set_list_header( 'Material Master Data - SALV Template' ).

  " Configure columns
  PERFORM setup_columns.

  " Set default sorting
  PERFORM setup_sorting.

  " Set layout
  PERFORM setup_layout.

  " Register events
  PERFORM setup_events.

ENDFORM.

*----------------------------------------------------------------------*
* Form: SETUP_COLUMNS
*----------------------------------------------------------------------*
FORM setup_columns.
  " Optimize column width
  go_columns->set_optimize( ).

  TRY.
      " Material Number
      go_column ?= go_columns->get_column( 'MATNR' ).
      go_column->set_long_text( 'Material Number' ).
      go_column->set_medium_text( 'Material No.' ).
      go_column->set_short_text( 'Mat.No.' ).

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
      " Handle column not found error
      MESSAGE 'Column not found' TYPE 'I'.
  ENDTRY.
ENDFORM.

*----------------------------------------------------------------------*
* Form: SETUP_SORTING
*----------------------------------------------------------------------*
FORM setup_sorting.
  TRY.
      " Add default sorting by material number
      go_sorts->add_sort( columnname = 'MATNR'
                          position   = 1
                          sequence   = if_salv_c_sort=>c_sort_asc ).

    CATCH cx_salv_not_found
          cx_salv_existing
          cx_salv_data_error.
      " Handle sorting errors
      MESSAGE 'Error setting up sorting' TYPE 'I'.
  ENDTRY.
ENDFORM.

*----------------------------------------------------------------------*
* Form: SETUP_LAYOUT
*----------------------------------------------------------------------*
FORM setup_layout.
  " Set layout key for saving user settings
  go_key = VALUE #( report = sy-repid ).
  go_layout->set_key( go_key ).
  go_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  go_layout->set_default( abap_true ).
ENDFORM.

*----------------------------------------------------------------------*
* Form: SETUP_EVENTS
*----------------------------------------------------------------------*
FORM setup_events.
  " Note: Event handling can be implemented here
  " Example: Double-click, toolbar button clicks, etc.
  " For now, this is a placeholder for future event handling
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

* Text symbols:
* 001    Selection Criteria