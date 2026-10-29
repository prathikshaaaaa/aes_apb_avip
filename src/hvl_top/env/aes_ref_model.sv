`ifndef AES_REF_MODEL_INCLUDED_
`define AES_REF_MODEL_INCLUDED_

class aes_ref_model extends uvm_object;
  `uvm_object_utils(aes_ref_model)

  localparam int AES_ROUNDS = 10;
  localparam int AES_ROWS = 4;
  localparam int AES_COLUMNS = 4;
  localparam int AES_STATE_BYTES = 16;
  localparam int AES_KEY_WORDS = 44;

  protected bit [7:0] sbox[256];
  protected bit [7:0] inverse_sbox[256];

  extern function new(string name = "aes_ref_model");
  extern protected virtual function void build_sboxes();
  extern virtual function aes_block_t encrypt(input aes_block_t plaintext, input aes_block_t key);
  extern virtual function aes_block_t decrypt(input aes_block_t ciphertext, input aes_block_t key);
  extern protected virtual function bit [7:0] gf_mul(input bit [7:0] a, input bit [7:0] b);
  extern protected virtual function bit [7:0] gf_inverse(input bit [7:0] value);
  extern protected virtual function bit [7:0] rotate_byte(input bit [7:0] value, input int amount);
  extern protected virtual function void expand_key(
    input aes_block_t key, output bit [31:0] words[AES_KEY_WORDS]);
  extern protected virtual function void add_round_key(
    ref bit [7:0] state[AES_STATE_BYTES],
    input bit [31:0] words[AES_KEY_WORDS],
    input int round_number);
  extern protected virtual function void sub_bytes(
    ref bit [7:0] state[AES_STATE_BYTES], input bit inverse);
  extern protected virtual function void shift_rows(
    ref bit [7:0] state[AES_STATE_BYTES], input bit inverse);
  extern protected virtual function void mix_columns(
    ref bit [7:0] state[AES_STATE_BYTES], input bit inverse);
  extern protected virtual function void block_to_state(
    input aes_block_t block, output bit [7:0] state[AES_STATE_BYTES]);
  extern protected virtual function aes_block_t state_to_block(
    input bit [7:0] state[AES_STATE_BYTES]);

endclass : aes_ref_model

function aes_ref_model::new(string name = "aes_ref_model");
  super.new(name);
  build_sboxes();
endfunction : new

function void aes_ref_model::build_sboxes();
  bit [7:0] inverse;
  bit [7:0] substituted;
  for(int i = 0; i < 256; i++) begin
    inverse = gf_inverse(i[7:0]);
    substituted = inverse ^ rotate_byte(inverse, 1) ^
                  rotate_byte(inverse, 2) ^ rotate_byte(inverse, 3) ^
                  rotate_byte(inverse, 4) ^ 8'h63;
    sbox[i] = substituted;
    inverse_sbox[substituted] = i[7:0];
  end
endfunction : build_sboxes

// Multiply bytes in GF(2^8), using the AES polynomial x^8+x^4+x^3+x+1.
function bit [7:0] aes_ref_model::gf_mul(input bit [7:0] a, input bit [7:0] b);
  bit [7:0] product;
  bit [7:0] x;
  bit [7:0] y;
  product = 0;
  x = a;
  y = b;
  repeat(8) begin
    if(y[0]) begin
      product ^= x;
    end
    x = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
    y >>= 1;
  end
  return product;
endfunction : gf_mul

function bit [7:0] aes_ref_model::gf_inverse(input bit [7:0] value);
  bit [7:0] result;
  bit [7:0] base;
  int unsigned exponent;
  result = 1;
  base = value;
  exponent = 254;
  while(exponent != 0) begin
    if(exponent[0]) begin
      result = gf_mul(result, base);
    end
    base = gf_mul(base, base);
    exponent >>= 1;
  end
  return result;
endfunction : gf_inverse

function bit [7:0] aes_ref_model::rotate_byte(input bit [7:0] value, input int amount);
  return (value << amount) | (value >> (8-amount));
endfunction : rotate_byte

// Expand four key words into eleven round keys (44 words).
function void aes_ref_model::expand_key(
  input aes_block_t key, output bit [31:0] words[AES_KEY_WORDS]);
  bit [31:0] temp;
  bit [7:0] rcon;
  rcon = 8'h01;
  for(int i = 0; i < 4; i++) begin
    words[i] = key[127-32*i -: 32];
  end
  for(int i = 4; i < AES_KEY_WORDS; i++) begin
    temp = words[i-1];
    if(i % 4 == 0) begin
      temp = {sbox[temp[23:16]], sbox[temp[15:8]], sbox[temp[7:0]], sbox[temp[31:24]]};
      temp ^= {rcon, 24'b0};
      rcon = gf_mul(rcon, 8'h02);
    end
    words[i] = words[i-4] ^ temp;
  end
endfunction : expand_key

function void aes_ref_model::add_round_key(
  ref bit [7:0] state[AES_STATE_BYTES],
  input bit [31:0] words[AES_KEY_WORDS],
  input int round_number);
  for(int column = 0; column < AES_COLUMNS; column++) begin
    for(int row = 0; row < AES_ROWS; row++) begin
      state[4*column+row] ^= words[4*round_number+column][31-8*row -: 8];
    end
  end
endfunction : add_round_key

function void aes_ref_model::sub_bytes(
  ref bit [7:0] state[AES_STATE_BYTES], input bit inverse);
  foreach(state[i]) begin
    state[i] = inverse ? inverse_sbox[state[i]] : sbox[state[i]];
  end
endfunction : sub_bytes

function void aes_ref_model::shift_rows(
  ref bit [7:0] state[AES_STATE_BYTES], input bit inverse);
  bit [7:0] previous[AES_STATE_BYTES];
  int source_column;
  previous = state;
  for(int row = 0; row < AES_ROWS; row++) begin
    for(int column = 0; column < AES_COLUMNS; column++) begin
      source_column = inverse ? (column+AES_COLUMNS-row)%AES_COLUMNS :
                                 (column+row)%AES_COLUMNS;
      state[4*column+row] = previous[4*source_column+row];
    end
  end
endfunction : shift_rows

function void aes_ref_model::mix_columns(
  ref bit [7:0] state[AES_STATE_BYTES], input bit inverse);
  bit [7:0] a;
  bit [7:0] b;
  bit [7:0] c;
  bit [7:0] d;
  for(int column = 0; column < AES_COLUMNS; column++) begin
    a = state[4*column];
    b = state[4*column+1];
    c = state[4*column+2];
    d = state[4*column+3];
    if(inverse) begin
      state[4*column] = gf_mul(a,8'h0e)^gf_mul(b,8'h0b)^gf_mul(c,8'h0d)^gf_mul(d,8'h09);
      state[4*column+1] = gf_mul(a,8'h09)^gf_mul(b,8'h0e)^gf_mul(c,8'h0b)^gf_mul(d,8'h0d);
      state[4*column+2] = gf_mul(a,8'h0d)^gf_mul(b,8'h09)^gf_mul(c,8'h0e)^gf_mul(d,8'h0b);
      state[4*column+3] = gf_mul(a,8'h0b)^gf_mul(b,8'h0d)^gf_mul(c,8'h09)^gf_mul(d,8'h0e);
    end
    else begin
      state[4*column] = gf_mul(a,8'h02)^gf_mul(b,8'h03)^c^d;
      state[4*column+1] = a^gf_mul(b,8'h02)^gf_mul(c,8'h03)^d;
      state[4*column+2] = a^b^gf_mul(c,8'h02)^gf_mul(d,8'h03);
      state[4*column+3] = gf_mul(a,8'h03)^b^c^gf_mul(d,8'h02);
    end
  end
endfunction : mix_columns

function void aes_ref_model::block_to_state(
  input aes_block_t block, output bit [7:0] state[AES_STATE_BYTES]);
  foreach(state[i]) begin
    state[i] = block[127-8*i -: 8];
  end
endfunction : block_to_state

function aes_block_t aes_ref_model::state_to_block(
  input bit [7:0] state[AES_STATE_BYTES]);
  aes_block_t block;
  foreach(state[i]) begin
    block[127-8*i -: 8] = state[i];
  end
  return block;
endfunction : state_to_block

function aes_block_t aes_ref_model::encrypt(input aes_block_t plaintext, input aes_block_t key);
  bit [7:0] state[AES_STATE_BYTES];
  bit [31:0] words[AES_KEY_WORDS];
  expand_key(key, words);
  block_to_state(plaintext, state);
  add_round_key(state, words, 0);
  for(int round_number = 1; round_number < AES_ROUNDS; round_number++) begin
    sub_bytes(state, 0);
    shift_rows(state, 0);
    mix_columns(state, 0);
    add_round_key(state, words, round_number);
  end
  sub_bytes(state, 0);
  shift_rows(state, 0);
  add_round_key(state, words, AES_ROUNDS);
  return state_to_block(state);
endfunction : encrypt

function aes_block_t aes_ref_model::decrypt(input aes_block_t ciphertext, input aes_block_t key);
  bit [7:0] state[AES_STATE_BYTES];
  bit [31:0] words[AES_KEY_WORDS];
  expand_key(key, words);
  block_to_state(ciphertext, state);
  add_round_key(state, words, AES_ROUNDS);
  for(int round_number = 9; round_number > 0; round_number--) begin
    shift_rows(state, 1);
    sub_bytes(state, 1);
    add_round_key(state, words, round_number);
    mix_columns(state, 1);
  end
  shift_rows(state, 1);
  sub_bytes(state, 1);
  add_round_key(state, words, 0);
  return state_to_block(state);
endfunction : decrypt

`endif
