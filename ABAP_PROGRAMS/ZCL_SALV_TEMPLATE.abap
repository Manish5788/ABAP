*&---------------------------------------------------------------------*
*& Class ZCL_SALV_TEMPLATE
*&---------------------------------------------------------------------*
*& Purpose: Modern OOP-based SALV Template Class
*& Author:  [Your Name]
*& Date:    [Current Date]
*& Description: Reusable class for creating SALV reports with
*&              encapsulated functionality and clean interfaces
*&---------------------------------------------------------------------*

CLASS zcl_salv_template DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Type definitions
    TYPES: BEGIN OF ty_output,
             matnr  TYPE mara-matnr,        " Material Number
             maktx  TYPE makt-maktx,        " Material Description
             mtart  TYPE mara-mtart,        " Material Type
             matkl  TYPE mara-matkl,        " Material Group
             meins  TYPE mara-meins,        " Base Unit
             ersda  TYPE mara-ersda,        " Created On
             ernam  TYPE mara-ernam,        " Created By
             laeda  TYPE mara-laeda,        " Changed On
             aenam  TYPE mara-aenam,        " Changed By
             lvorm  TYPE mara-lvorm,        " Deletion Flag
             status TYPE icon-id,           " Status Icon
           END OF ty_output,
           tt_output TYPE TABLE OF ty_output.

    " Selection parameters structure
    TYPES: BEGIN OF ty_selection,
             matnr_range TYPE RANGE OF mara-matnr,
             mtart_range TYPE RANGE OF mara-mtart,
             matkl_range TYPE RANGE OF mara-matkl,
             ersda_range TYPE RANGE OF mara-ersda,
             max_rows    TYPE i,
           END OF ty_selection.

    " Configuration structure
    TYPES: BEGIN OF ty_config,
             zebra_pattern   TYPE abap_bool,
             save_layout     TYPE abap_bool,
             show_toolbar    TYPE abap_bool,
             show_totals     TYPE abap_bool,
             editable        TYPE abap_bool,
           END OF ty_config.

    " Constants
    CONSTANTS: c_refresh      TYPE salv_de_function VALUE 'REFRESH',
               c_export_excel TYPE salv_de_function VALUE 'EXPORT_EXCEL',
               c_show_details TYPE salv_de_function VALUE 'SHOW_DETAILS'.

    " Constructor
    METHODS: constructor
               IMPORTING
                 iv_title  TYPE string OPTIONAL
                 is_config TYPE ty_config OPTIONAL.

    " Main methods
    METHODS: set_data
               IMPORTING
                 it_data TYPE tt_output,

             set_selection_criteria
               IMPORTING
                 is_selection TYPE ty_selection,

             display
               RETURNING
                 VALUE(ro_salv) TYPE REF TO cl_salv_table
               RAISING
                 cx_salv_msg,

             refresh_data
               RAISING
                 cx_salv_msg,

             get_selected_rows
               RETURNING
                 VALUE(rt_rows) TYPE salv_t_row.

    " Event handling
    METHODS: on_link_click FOR EVENT link_click OF cl_salv_events_table
               IMPORTING row column,
             on_double_click FOR EVENT double_click OF cl_salv_events_table
               IMPORTING row column,
             on_added_function FOR EVENT added_function OF cl_salv_events
               IMPORTING e_salv_function.

  PRIVATE SECTION.
    " Instance variables
    DATA: mt_data         TYPE tt_output,
          ms_selection    TYPE ty_selection,
          ms_config       TYPE ty_config,
          mv_title        TYPE string,
          mo_salv         TYPE REF TO cl_salv_table,
          mo_functions    TYPE REF TO cl_salv_functions_list,
          mo_display      TYPE REF TO cl_salv_display_settings,
          mo_columns      TYPE REF TO cl_salv_columns_table,
          mo_events       TYPE REF TO cl_salv_events_table,
          mo_sorts        TYPE REF TO cl_salv_sorts,
          mo_layout       TYPE REF TO cl_salv_layout.

    " Private methods
    METHODS: create_salv
               RAISING
                 cx_salv_msg,

             configure_display,

             configure_columns
               RAISING
                 cx_salv_not_found,

             configure_functions
               RAISING
                 cx_salv_existing
                 cx_salv_wrong_call,

             configure_events,

             configure_layout,

             configure_sorting
               RAISING
                 cx_salv_not_found
                 cx_salv_existing
                 cx_salv_data_error,

             get_data_from_db
               RAISING
                 cx_sy_open_sql_db,

             process_data_icons.

ENDCLASS.

*&---------------------------------------------------------------------*
*& Class Implementation
*&---------------------------------------------------------------------*
CLASS zcl_salv_template IMPLEMENTATION.

  METHOD constructor.
    " Initialize configuration with defaults
    ms_config-zebra_pattern = abap_true.
    ms_config-save_layout   = abap_true.
    ms_config-show_toolbar  = abap_true.
    ms_config-show_totals   = abap_false.
    ms_config-editable      = abap_false.

    " Override with provided configuration
    IF is_config IS NOT INITIAL.
      ms_config = is_config.
    ENDIF.

    " Set title
    mv_title = COND #( WHEN iv_title IS NOT INITIAL 
                       THEN iv_title 
                       ELSE 'SALV Template Report' ).
  ENDMETHOD.

  METHOD set_data.
    mt_data = it_data.
  ENDMETHOD.

  METHOD set_selection_criteria.
    ms_selection = is_selection.
  ENDMETHOD.

  METHOD display.
    " Get data if not provided directly
    IF mt_data IS INITIAL AND ms_selection IS NOT INITIAL.
      get_data_from_db( ).
    ENDIF.

    " Process data (add icons, etc.)
    process_data_icons( ).

    " Create and configure SALV
    create_salv( ).
    configure_display( ).
    configure_columns( ).
    configure_functions( ).
    configure_events( ).
    configure_layout( ).
    configure_sorting( ).

    " Display the ALV
    mo_salv->display( ).
    ro_salv = mo_salv.
  ENDMETHOD.

  METHOD create_salv.
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = mo_salv
      CHANGING
        t_table      = mt_data ).

    " Get object references
    mo_functions = mo_salv->get_functions( ).
    mo_display   = mo_salv->get_display_settings( ).
    mo_columns   = mo_salv->get_columns( ).
    mo_events    = mo_salv->get_event( ).
    mo_sorts     = mo_salv->get_sorts( ).
    mo_layout    = mo_salv->get_layout( ).
  ENDMETHOD.

  METHOD configure_display.
    " Set zebra pattern if configured
    IF ms_config-zebra_pattern = abap_true.
      mo_display->set_striped_pattern( cl_salv_display_settings=>true ).
    ENDIF.

    " Set list header
    mo_display->set_list_header( CONV #( mv_title ) ).

    " Set other display properties
    mo_display->set_horizontal_lines( abap_false ).
    mo_display->set_suppress_empty_data( abap_true ).
  ENDMETHOD.

  METHOD configure_columns.
    DATA: lo_column TYPE REF TO cl_salv_column_table.

    " Optimize all columns
    mo_columns->set_optimize( ).

    " Configure Status column
    TRY.
        lo_column ?= mo_columns->get_column( 'STATUS' ).
        lo_column->set_long_text( 'Status' ).
        lo_column->set_medium_text( 'Status' ).
        lo_column->set_short_text( 'Stat' ).
        lo_column->set_icon( if_salv_c_bool_sap=>true ).
        lo_column->set_alignment( if_salv_c_alignment=>centered ).
      CATCH cx_salv_not_found.
    ENDTRY.

    " Configure Material Number with hotspot
    TRY.
        lo_column ?= mo_columns->get_column( 'MATNR' ).
        lo_column->set_long_text( 'Material Number' ).
        lo_column->set_medium_text( 'Material No.' ).
        lo_column->set_short_text( 'Mat.No.' ).
        lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        lo_column->set_key( if_salv_c_bool_sap=>true ).
      CATCH cx_salv_not_found.
    ENDTRY.

    " Configure other columns
    TRY.
        lo_column ?= mo_columns->get_column( 'MAKTX' ).
        lo_column->set_long_text( 'Material Description' ).
        lo_column->set_medium_text( 'Description' ).
        lo_column->set_short_text( 'Desc.' ).
      CATCH cx_salv_not_found.
    ENDTRY.

    TRY.
        lo_column ?= mo_columns->get_column( 'MTART' ).
        lo_column->set_long_text( 'Material Type' ).
        lo_column->set_medium_text( 'Mat. Type' ).
        lo_column->set_short_text( 'Type' ).
      CATCH cx_salv_not_found.
    ENDTRY.

    TRY.
        lo_column ?= mo_columns->get_column( 'ERSDA' ).
        lo_column->set_long_text( 'Created On' ).
        lo_column->set_medium_text( 'Created' ).
        lo_column->set_short_text( 'Crtd' ).
      CATCH cx_salv_not_found.
    ENDTRY.
  ENDMETHOD.

  METHOD configure_functions.
    IF ms_config-show_toolbar = abap_true.
      " Enable standard functions
      mo_functions->set_all( ).

      " Add custom functions
      mo_functions->add_function(
        name     = c_refresh
        icon     = icon_refresh
        text     = 'Refresh'
        tooltip  = 'Refresh data from database'
        position = if_salv_c_function_position=>right_of_salv_functions ).

      mo_functions->add_function(
        name     = c_export_excel
        icon     = icon_xxl
        text     = 'Excel Export'
        tooltip  = 'Export to Excel'
        position = if_salv_c_function_position=>right_of_salv_functions ).

      mo_functions->add_function(
        name     = c_show_details
        icon     = icon_detail
        text     = 'Details'
        tooltip  = 'Show details'
        position = if_salv_c_function_position=>right_of_salv_functions ).
    ENDIF.
  ENDMETHOD.

  METHOD configure_events.
    " Register event handlers
    SET HANDLER me->on_link_click FOR mo_events.
    SET HANDLER me->on_double_click FOR mo_events.
    SET HANDLER me->on_added_function FOR mo_events.
  ENDMETHOD.

  METHOD configure_layout.
    IF ms_config-save_layout = abap_true.
      DATA: ls_key TYPE salv_s_layout_key.
      ls_key-report = sy-repid.
      mo_layout->set_key( ls_key ).
      mo_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
      mo_layout->set_default( abap_true ).
    ENDIF.
  ENDMETHOD.

  METHOD configure_sorting.
    " Add default sorting by material number
    mo_sorts->add_sort(
      columnname = 'MATNR'
      position   = 1
      sequence   = if_salv_c_sort=>c_sort_asc ).
  ENDMETHOD.

  METHOD get_data_from_db.
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
                         AND t~spras = @sy-langu
      INTO CORRESPONDING FIELDS OF TABLE @mt_data
      WHERE m~matnr IN @ms_selection-matnr_range
        AND m~mtart IN @ms_selection-mtart_range
        AND m~matkl IN @ms_selection-matkl_range
        AND m~ersda IN @ms_selection-ersda_range
      UP TO @ms_selection-max_rows ROWS.
  ENDMETHOD.

  METHOD process_data_icons.
    FIELD-SYMBOLS: <ls_data> TYPE ty_output.

    LOOP AT mt_data ASSIGNING <ls_data>.
      " Set status icon based on deletion flag
      IF <ls_data>-lvorm IS NOT INITIAL.
        <ls_data>-status = icon_red_light.
      ELSE.
        <ls_data>-status = icon_green_light.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD refresh_data.
    IF ms_selection IS NOT INITIAL.
      CLEAR: mt_data.
      get_data_from_db( ).
      process_data_icons( ).
      mo_salv->refresh( ).
      MESSAGE 'Data refreshed successfully' TYPE 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD get_selected_rows.
    DATA: lo_selections TYPE REF TO cl_salv_selections.
    lo_selections = mo_salv->get_selections( ).
    rt_rows = lo_selections->get_selected_rows( ).
  ENDMETHOD.

  METHOD on_link_click.
    FIELD-SYMBOLS: <ls_data> TYPE ty_output.
    READ TABLE mt_data ASSIGNING <ls_data> INDEX row.
    IF sy-subrc = 0.
      CASE column.
        WHEN 'MATNR'.
          MESSAGE |Material { <ls_data>-matnr } selected| TYPE 'I'.
          " Implement navigation logic here
          " SET PARAMETER ID 'MAT' FIELD <ls_data>-matnr.
          " CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
      ENDCASE.
    ENDIF.
  ENDMETHOD.

  METHOD on_double_click.
    FIELD-SYMBOLS: <ls_data> TYPE ty_output.
    READ TABLE mt_data ASSIGNING <ls_data> INDEX row.
    IF sy-subrc = 0.
      MESSAGE |Double-clicked on row { row }, column { column }| TYPE 'I'.
      " Implement double-click logic here
    ENDIF.
  ENDMETHOD.

  METHOD on_added_function.
    CASE e_salv_function.
      WHEN c_refresh.
        TRY.
            refresh_data( ).
          CATCH cx_salv_msg INTO DATA(lx_error).
            MESSAGE lx_error->get_text( ) TYPE 'E'.
        ENDTRY.

      WHEN c_export_excel.
        " Implement Excel export
        MESSAGE 'Excel export functionality would be implemented here' TYPE 'I'.

      WHEN c_show_details.
        DATA: lv_count TYPE i.
        DESCRIBE TABLE mt_data LINES lv_count.
        MESSAGE |Total records: { lv_count }| TYPE 'I'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& Report using the class
*&---------------------------------------------------------------------*
REPORT z_salv_class_demo.

" Selection screen
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

INITIALIZATION.
  " Set default date range
  s_ersda-sign   = 'I'.
  s_ersda-option = 'BT'.
  s_ersda-low    = sy-datum - 365.
  s_ersda-high   = sy-datum.
  APPEND s_ersda.

START-OF-SELECTION.
  " Create instance of the SALV class
  DATA: lo_salv_template TYPE REF TO zcl_salv_template,
        ls_selection     TYPE zcl_salv_template=>ty_selection,
        ls_config        TYPE zcl_salv_template=>ty_config.

  " Prepare selection criteria
  ls_selection-matnr_range = s_matnr[].
  ls_selection-mtart_range = s_mtart[].
  ls_selection-matkl_range = s_matkl[].
  ls_selection-ersda_range = s_ersda[].
  ls_selection-max_rows    = p_maxrow.

  " Prepare configuration
  ls_config-zebra_pattern = p_zebra.
  ls_config-save_layout   = p_layout.
  ls_config-show_toolbar  = abap_true.

  " Create and display SALV
  TRY.
      CREATE OBJECT lo_salv_template
        EXPORTING
          iv_title  = 'Material Master Data - Class-based SALV'
          is_config = ls_config.

      lo_salv_template->set_selection_criteria( ls_selection ).
      lo_salv_template->display( ).

    CATCH cx_salv_msg INTO DATA(lx_error).
      MESSAGE lx_error->get_text( ) TYPE 'E'.
  ENDTRY.

*----------------------------------------------------------------------*
* Text Symbols
*----------------------------------------------------------------------*
* 001    Selection Criteria
* 002    Display Options