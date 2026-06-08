REPORT z_demo_capabilities.

**************************************
* SAP ABAP Capability Showcase
* Modern ABAP Patterns & Techniques
**************************************

CLASS lcl_employee DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_employee,
             id         TYPE i,
             name       TYPE string,
             department TYPE string,
             salary     TYPE i,
             hired_on   TYPE d,
             is_active  TYPE abap_bool,
           END OF ty_employee,
           tt_employees TYPE STANDARD TABLE OF ty_employee WITH EMPTY KEY.

    METHODS constructor IMPORTING iv_name TYPE string.
    METHODS display.
    METHODS promote IMPORTING iv_raise TYPE i.
  PRIVATE SECTION.
    DATA mv_name TYPE string.
ENDCLASS.

CLASS lcl_employee IMPLEMENTATION.
  METHOD constructor.
    mv_name = iv_name.
  ENDMETHOD.
  METHOD display.
    WRITE: / |Employee: { mv_name }|.
  ENDMETHOD.
  METHOD promote.
    WRITE: / |{ mv_name } got a raise of { iv_raise }!|.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_demo DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS run.
  PRIVATE SECTION.
    CLASS-METHODS:
      demo_inline_declarations,
      demo_string_operations,
      demo_internal_tables,
      demo_constructor_expressions,
      demo_loops_reduce_filter,
      demo_date_time,
      demo_exceptions,
      demo_messaging,
      demo_open_sql.
ENDCLASS.

CLASS lcl_demo IMPLEMENTATION.

  METHOD run.
    demo_inline_declarations( ).
    demo_string_operations( ).
    demo_internal_tables( ).
    demo_constructor_expressions( ).
    demo_loops_reduce_filter( ).
    demo_date_time( ).
    demo_exceptions( ).
    demo_messaging( ).
    demo_open_sql( ).
  ENDMETHOD.

  METHOD demo_inline_declarations.
    WRITE: / '=== 1. Inline Declarations (DATA(...)) ==='.

    DATA(lv_text) = `Hello ABAP!`.
    DATA(lv_number) = 42.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    DATA(lv_time) = cl_abap_context_info=>get_system_time( ).

    WRITE: / |String: { lv_text }, Number: { lv_number }|.
    WRITE: / |Date: { lv_today DATE = USER }, Time: { lv_time TIME = USER }|.

    FIELD-SYMBOLS <fs_text> LIKE lv_text.
    ASSIGN lv_text TO <fs_text>.
    IF <fs_text> IS ASSIGNED.
      WRITE: / |Field-Symbol: { <fs_text> }|.
    ENDIF.
  ENDMETHOD.

  METHOD demo_string_operations.
    WRITE: / '=== 2. String Operations ==='.

    DATA(lv_string) = `  SAP ABAP is powerful  `.
    DATA(lv_trimmed) = shift_right( val = shift_left( val = lv_string ) ).

    WRITE: / |Original: '{ lv_string }'|.
    WRITE: / |Trimmed:  '{ lv_trimmed }'|.

    DATA(lv_upper) = to_upper( lv_string ).
    DATA(lv_lower) = to_lower( lv_string ).
    DATA(lv_template) = |Upper: { lv_upper }, Lower: { lv_lower }|.

    FIND ALL OCCURRENCES OF `ABAP` IN lv_string
      MATCH COUNT DATA(lv_count).
    WRITE: / |Occurrences of 'ABAP': { lv_count }|.

    SPLIT `alpha,beta,gamma` AT `,` INTO TABLE DATA(lt_parts).
    WRITE: / |Split result: { lines( lt_parts ) } parts|.

    DATA(lv_concatenated) = concat_lines_of(
      table = lt_parts
      sep   = ` | ` ).
    WRITE: / |Joined: { lv_concatenated }|.
  ENDMETHOD.

  METHOD demo_internal_tables.
    WRITE: / '=== 3. Internal Table Operations ==='.

    DATA lt_employees TYPE lcl_employee=>tt_employees.

    lt_employees = VALUE #(
      ( id = 1 name = `Alice`   department = `Engineering` salary = 80000  hired_on = `20200101` is_active = abap_true  )
      ( id = 2 name = `Bob`     department = `Marketing`  salary = 65000  hired_on = `20190615` is_active = abap_true  )
      ( id = 3 name = `Charlie` department = `Engineering` salary = 95000  hired_on = `20180301` is_active = abap_false )
      ( id = 4 name = `Diana`   department = `Sales`      salary = 72000  hired_on = `20211101` is_active = abap_true  )
      ( id = 5 name = `Eve`     department = `Marketing`  salary = 58000  hired_on = `20220701` is_active = abap_true  )
    ).

    WRITE: / |Total employees: { lines( lt_employees ) }|.

    DATA(lt_active) = FILTER #( lt_employees USING KEY primary_ KEY
      WHERE is_active = abap_true ).
    WRITE: / |Active employees: { lines( lt_active ) }|.

    SORT lt_employees BY salary DESCENDING.
    DATA(ls_top) = lt_employees[ 1 ].
    WRITE: / |Highest paid: { ls_top-name } ({ ls_top-salary })|.

    TRY.
        DATA(ls_eng) = lt_employees[ department = `Engineering` ].
        WRITE: / |First Engineer: { ls_eng-name }|.
      CATCH cx_sy_itab_line_not_found.
        WRITE: / |No engineers found|.
    ENDTRY.
  ENDMETHOD.

  METHOD demo_constructor_expressions.
    WRITE: / '=== 4. Constructor Expressions ==='.

    TYPES: BEGIN Of ty_sales,
             product TYPE string,
             region  TYPE string,
             amount  TYPE i,
           END OF ty_sales,
           tt_sales TYPE STANDARD TABLE Of ty_sales WITH EMPTY KEY.

    DATA(lt_sales) = VALUE tt_sales(
      ( product = `Laptop`  region = `NA` amount = 1200 )
      ( product = `Laptop`  region = `EU` amount = 900  )
      ( product = `Phone`   region = `NA` amount = 1500 )
      ( product = `Phone`   region = `EU` amount = 1100 )
      ( product = `Tablet`  region = `NA` amount = 600  )
    ).

    DATA(lt_high_value) = VALUE tt_sales(
      FOR ls IN lt_sales WHERE ( amount >= 1000 )
      ( ls ) ).
    WRITE: / |High value sales: { lines( lt_high_value ) }|.

    DATA(lv_total_na) = REDUCE i(
      INIT lv_sum = 0
      FOR ls IN lt_sales
      WHERE ( region = `NA` )
      NEXT lv_sum = lv_sum + ls-amount ).
    WRITE: / |Total NA sales: { lv_total_na }|.

    DATA(lv_total) = REDUCE i(
      INIT lv_sum = 0
      FOR ls IN lt_sales
      NEXT lv_sum = lv_sum + ls-amount ).
    WRITE: / |Total all sales: { lv_total }|.

    DATA lt_aggregated TYPE SORTED TABLE OF ty_sales
      WITH NON-UNIQUE KEY product.
    lt_aggregated = CORRESPONDING #( lt_sales ).
    LOOP AT lt_aggregated INTO DATA(ls_group).
      DATA(lv_product) = ls_group-product.
      DATA(lv_count) = REDUCE i(
        INIT lv_cnt = 0
        FOR ls IN lt_sales
        WHERE ( product = lv_product )
        NEXT lv_cnt = lv_cnt + 1 ).
      WRITE: / |Product: { ls_group-product } -> Count: { lv_count }|.
    ENDLOOP.

    DATA(lt_na) = FILTER tt_sales( lt_sales EXCEPT IN region WHERE region = `NA` ).
    WRITE: / |Non-NA sales: { lines( lt_na ) }|.
  ENDMETHOD.

  METHOD demo_loops_reduce_filter.
    WRITE: / '=== 5. FOR, REDUCE, FILTER, GROUP BY ==='.

    TYPES: BEGIN OF ty_order,
             customer TYPE string,
             item     TYPE string,
             price    TYPE i,
             qty      TYPE i,
           END OF ty_order,
           tt_orders TYPE STANDARD TABLE OF ty_order WITH EMPTY KEY.

    DATA(lt_orders) = VALUE tt_orders(
      ( customer = `Acme`  item = `Widget`  price = 100 qty = 5  )
      ( customer = `Beta`  item = `Gadget`  price = 200 qty = 3  )
      ( customer = `Acme`  item = `Gadget`  price = 200 qty = 2  )
      ( customer = `Gamma` item = `Widget`  price = 100 qty = 4  )
      ( customer = `Acme`  item = `Widget`  price = 100 qty = 3  )
    ).

    DATA(lt_with_total) = VALUE #(
      FOR ls IN lt_orders
      LET lv_total = ls-price * ls-qty IN
      ( VALUE ty_order( BASE ls ) ) ).
    " Append totals
    DATA lv_grand_total TYPE i.
    LOOP AT lt_orders REFERENCE INTO DATA(lr_o).
      lv_grand_total += lr_o->price * lr_o->qty.
    ENDLOOP.
    WRITE: / |Grand total: { lv_grand_total }|.

    DATA(lt_acme) = FILTER tt_orders( lt_orders USING KEY primary_key
      WHERE customer = `Acme` ).
    WRITE: / |Acme orders: { lines( lt_acme ) }|.

    DATA(lv_total_acme) = REDUCE i(
      INIT sum = 0
      FOR ls IN lt_orders
      WHERE ( customer = `Acme` )
      NEXT sum = sum + ( ls-price * ls-qty ) ).
    WRITE: / |Acme total: { lv_total_acme }|.
  ENDMETHOD.

  METHOD demo_date_time.
    WRITE: / '=== 6. Date/Time & Timestamps ==='.

    DATA(lv_now_ts) = utclong_current( ).
    WRITE: / |UTC Timestamp: { lv_now_ts }|.

    DATA(lv_date) = cl_abap_context_info=>get_system_date( ).
    DATA(lv_time) = cl_abap_context_info=>get_system_time( ).
    WRITE: / |System Date: { lv_date DATE = USER }|.
    WRITE: / |System Time: { lv_time TIME = USER }|.

    DATA(lv_year) = lv_date+0(4).
    DATA(lv_month) = lv_date+4(2).
    DATA(lv_day) = lv_date+6(2).
    WRITE: / |Extracted: Year={ lv_year }, Month={ lv_month }, Day={ lv_day }|.

    DATA(lv_future) = lv_date + 30.
    WRITE: / |30 days from now: { lv_future DATE = USER }|.

    DATA(lo_calendar) = cl_hr99s00_calculation=>get_date_difference(
      iv_date1 = lv_date
      iv_date2 = lv_future ).
    WRITE: / |Days between: 30|.
  ENDMETHOD.

  METHOD demo_exceptions.
    WRITE: / '=== 7. Exception Handling ==='.

    TRY.
        DATA(lv_result) = 1 / 0.
      CATCH cx_sy_zerodivide INTO DATA(lx_zero).
        WRITE: / |Caught division by zero: { lx_zero->get_text( ) }|.
    ENDTRY.

    TRY.
        DATA(lv_whats_this) = 1 / 1. " succeeds
        WRITE: / |1 / 1 = { lv_whats_this }|.
      CATCH cx_root INTO DATA(lx_err).
        WRITE: / |Unexpected: { lx_err->get_text( ) }|.
    ENDTRY.

    DATA lx_exc TYPE REF TO cx_demo_constructor.
    TRY.
        RAISE EXCEPTION TYPE cx_demo_constructor
          EXPORTING textid = cx_demo_constructor=>cx_demo_constructor
                    mytext = `Custom exception raised!`.
      CATCH cx_demo_constructor INTO DATA(lx_demo).
        WRITE: / |{ lx_demo->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.

  METHOD demo_messaging.
    WRITE: / '=== 8. Messaging & Output ==='.

    MESSAGE |This is an info message| TYPE 'I' DISPLAY LIKE 'I'.

    DATA(lv_formatted) = |{ 12345678 NUMBER = USER }|.
    WRITE: / |Formatted number: { lv_formatted }|.

    DATA(lv_fraction) = |{ 3 / 4 DECIMALS = 2 }|.
    WRITE: / |Fraction: { lv_fraction }|.
  ENDMETHOD.

  METHOD demo_open_sql.
    WRITE: / '=== 9. Open SQL ==='.

    SELECT SINGLE FROM t000
      FIELDS name
      INTO @DATA(lv_client_name).
    IF sy-subrc = 0.
      WRITE: / |Client Name: { lv_client_name }|.
    ENDIF.

    SELECT FROM t000
      FIELDS mandt, name
      ORDER BY mandt
      INTO TABLE @DATA(lt_clients)
      UP TO 3 ROWS.
    WRITE: / |Clients found: { lines( lt_clients ) }|.

    SELECT FROM dd02l
      FIELDS tabname, ddtext
      WHERE tabname LIKE 'T%'
        AND as4local = 'A'
      ORDER BY tabname
      INTO TABLE @DATA(lt_tables)
      UP TO 3 ROWS.
    WRITE: / |Tables starting with T: { lines( lt_tables ) }|.
    IF lt_tables IS NOT INITIAL.
      DATA(ls_first) = lt_tables[ 1 ].
      WRITE: / |First: { ls_first-tabname }|.
    ENDIF.

    WRITE: / |SQL executed successfully|.
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  WRITE: / '=========================================='.
  WRITE: / '  SAP ABAP Modern Capabilities Demo'.
  WRITE: / '=========================================='.
  WRITE: / ''.

  lcl_demo=>run( ).

  WRITE: / ''.
  WRITE: / '=========================================='.
  WRITE: / '  Demo Complete.'.
  WRITE: / '=========================================='.
