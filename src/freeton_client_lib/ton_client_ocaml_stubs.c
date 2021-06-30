#define CAML_NAME_SPACE
#include "caml/mlvalues.h"
#include "caml/alloc.h"
#include "caml/memory.h"
#include "caml/callback.h"


#include <pthread.h>
#include <caml/threads.h>
#include <string.h>

#include "tonclient.h"

typedef struct tc_response tc_response ;

struct tc_response {
    uint32_t request_id ;
    tc_string_data_t params_json ;
    uint32_t response_type ;
    bool finished ;
    tc_response* next ;
  } ;

static pthread_mutex_t mutex ;
static pthread_cond_t condition ;

static tc_response* fifo_entry = NULL ;
static tc_response* fifo_exit = NULL ;

CAMLprim value tc_create_context_ml ( value config_ml )
{
   CAMLparam1( config_ml );
   CAMLlocal1( json_ml ) ;
   tc_string_data_t data ;
   data.content = String_val( config_ml ) ;
   data.len = caml_string_length( config_ml );
   tc_string_handle_t* json_ptr = tc_create_context( data );
   data = tc_read_string(json_ptr);
   json_ml = caml_alloc_initialized_string( data.len, data.content );
   tc_destroy_string( json_ptr );
   CAMLreturn( json_ml ) ;
}

CAMLprim value has_tc_response_ml ( value unit )
{
  if( fifo_exit == NULL && fifo_entry == NULL ) {
    return Val_false ;
  } else {
    return Val_true ;
  }
}

CAMLprim value get_tc_response_ml ( value unit )
{
  CAMLparam0();
  CAMLlocal1( res_ml );

  if( fifo_exit == NULL ){

    caml_release_runtime_system() ;
    pthread_mutex_lock( &mutex );
    while( fifo_entry == NULL ){
      pthread_cond_wait( &condition, &mutex );
    }

    while( fifo_entry != NULL ){
      tc_response *r = fifo_exit ;
      fifo_exit = fifo_entry ;
      fifo_entry = fifo_exit->next ;
      fifo_exit->next = r ;
    }

    pthread_mutex_unlock( &mutex );
    caml_acquire_runtime_system();
  }

  tc_response* r = fifo_exit ;
  fifo_exit = r->next ;

  if( r->response_type > 4 ) r->response_type = 5 ;

  res_ml = caml_alloc( /*mlsize=*/ 4, 0 );
  Field( res_ml, 0 ) = Val_int( r->request_id );
  caml_initialize( &Field( res_ml, 1 ) ,
                   caml_alloc_initialized_string(
                                                 r->params_json.len,
                                                 r->params_json.content ) );
  Field( res_ml, 2 ) = Val_int( r->response_type );
  Field( res_ml, 3 ) = Val_bool( r->finished );

  CAMLreturn( res_ml );
}


CAMLprim value tc_destroy_context_ml ( value context_ml )
{
  tc_destroy_context( Int_val( context_ml ));
  return Val_unit;
}


static void tc_response_handler (
    uint32_t request_id,
    tc_string_data_t params_json,
    uint32_t response_type,
    bool finished)
{
   pthread_mutex_lock( &mutex );

   tc_response* r = ( tc_response* ) malloc( sizeof( tc_response ));
   r->request_id = request_id ;
   r->params_json.len = params_json.len ;
   char* content = malloc ( params_json.len );
   r->params_json.content = content ;
   memcpy( content, params_json.content, params_json.len );
   r->response_type = response_type ;
   r->finished = finished ;
   r->next = fifo_entry ;
   fifo_entry = r;

   pthread_mutex_unlock( &mutex );
   pthread_cond_signal ( &condition );
}

CAMLprim value tc_request_ml (
                              value context_ml,
                              value function_name_ml,
                              value function_params_json_ml,
                              value request_id_ml
                              )
{
  CAMLparam2( function_name_ml, function_params_json_ml );
  tc_string_data_t function_name ;
  tc_string_data_t function_params_json ;

  function_name.content = String_val ( function_name_ml );
  function_name.len = caml_string_length( function_name_ml );
  function_params_json.content = String_val ( function_params_json_ml );
  function_params_json.len = caml_string_length ( function_params_json_ml );

  tc_request(
             Int_val( context_ml ),
             function_name,
             function_params_json,
             Int_val( request_id_ml ),
             tc_response_handler
             ) ;
  return Val_unit ;
}


CAMLprim value tc_request_sync_ml (
                              value context_ml,
                              value function_name_ml,
                              value function_params_json_ml
                              )
{
  CAMLparam2( function_name_ml, function_params_json_ml );
  CAMLlocal1( json_ml );
  tc_string_data_t function_name ;
  tc_string_data_t function_params_json ;

  function_name.content = String_val ( function_name_ml );
  function_name.len = caml_string_length( function_name_ml );
  function_params_json.content = String_val ( function_params_json_ml );
  function_params_json.len = caml_string_length ( function_params_json_ml );

  tc_string_handle_t* json_ptr = tc_request_sync(
             Int_val( context_ml ),
             function_name,
             function_params_json
             ) ;
  tc_string_data_t data = tc_read_string(json_ptr) ;
  json_ml = caml_alloc_initialized_string( data.len, data.content );
  tc_destroy_string( json_ptr );
  CAMLreturn( json_ml ) ;
}


value tc_init_ml( value unit )
{
  pthread_mutex_init( &mutex, NULL );
  pthread_cond_init( &condition, NULL );

  return Val_unit ;
}
