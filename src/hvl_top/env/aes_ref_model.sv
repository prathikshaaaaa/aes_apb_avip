`ifndef AES_REF_MODEL_INCLUDED_
`define AES_REF_MODEL_INCLUDED_

class aes_ref_model extends uvm_object;
  `uvm_object_utils(aes_ref_model)

  localparam int AES_ROUNDS = 10;
  localparam int AES_ROWS = 4;
  localparam int AES_COLUMNS = 4;
  localparam int AES_STATE_BYTES = 16;
  localparam int AES_KEY_WORDS = 44;
  typedef bit [7:0] aes_state_t[4][4];

  localparam logic [7:0] SBOX [256] = '{
    8'h63,8'h7c,8'h77,8'h7b,8'hf2,8'h6b,8'h6f,8'hc5,8'h30,8'h01,8'h67,8'h2b,8'hfe,8'hd7,8'hab,8'h76,
    8'hca,8'h82,8'hc9,8'h7d,8'hfa,8'h59,8'h47,8'hf0,8'had,8'hd4,8'ha2,8'haf,8'h9c,8'ha4,8'h72,8'hc0,
    8'hb7,8'hfd,8'h93,8'h26,8'h36,8'h3f,8'hf7,8'hcc,8'h34,8'ha5,8'he5,8'hf1,8'h71,8'hd8,8'h31,8'h15,
    8'h04,8'hc7,8'h23,8'hc3,8'h18,8'h96,8'h05,8'h9a,8'h07,8'h12,8'h80,8'he2,8'heb,8'h27,8'hb2,8'h75,
    8'h09,8'h83,8'h2c,8'h1a,8'h1b,8'h6e,8'h5a,8'ha0,8'h52,8'h3b,8'hd6,8'hb3,8'h29,8'he3,8'h2f,8'h84,
    8'h53,8'hd1,8'h00,8'hed,8'h20,8'hfc,8'hb1,8'h5b,8'h6a,8'hcb,8'hbe,8'h39,8'h4a,8'h4c,8'h58,8'hcf,
    8'hd0,8'hef,8'haa,8'hfb,8'h43,8'h4d,8'h33,8'h85,8'h45,8'hf9,8'h02,8'h7f,8'h50,8'h3c,8'h9f,8'ha8,
    8'h51,8'ha3,8'h40,8'h8f,8'h92,8'h9d,8'h38,8'hf5,8'hbc,8'hb6,8'hda,8'h21,8'h10,8'hff,8'hf3,8'hd2,
    8'hcd,8'h0c,8'h13,8'hec,8'h5f,8'h97,8'h44,8'h17,8'hc4,8'ha7,8'h7e,8'h3d,8'h64,8'h5d,8'h19,8'h73,
    8'h60,8'h81,8'h4f,8'hdc,8'h22,8'h2a,8'h90,8'h88,8'h46,8'hee,8'hb8,8'h14,8'hde,8'h5e,8'h0b,8'hdb,
    8'he0,8'h32,8'h3a,8'h0a,8'h49,8'h06,8'h24,8'h5c,8'hc2,8'hd3,8'hac,8'h62,8'h91,8'h95,8'he4,8'h79,
    8'he7,8'hc8,8'h37,8'h6d,8'h8d,8'hd5,8'h4e,8'ha9,8'h6c,8'h56,8'hf4,8'hea,8'h65,8'h7a,8'hae,8'h08,
    8'hba,8'h78,8'h25,8'h2e,8'h1c,8'ha6,8'hb4,8'hc6,8'he8,8'hdd,8'h74,8'h1f,8'h4b,8'hbd,8'h8b,8'h8a,
    8'h70,8'h3e,8'hb5,8'h66,8'h48,8'h03,8'hf6,8'h0e,8'h61,8'h35,8'h57,8'hb9,8'h86,8'hc1,8'h1d,8'h9e,
    8'he1,8'hf8,8'h98,8'h11,8'h69,8'hd9,8'h8e,8'h94,8'h9b,8'h1e,8'h87,8'he9,8'hce,8'h55,8'h28,8'hdf,
    8'h8c,8'ha1,8'h89,8'h0d,8'hbf,8'he6,8'h42,8'h68,8'h41,8'h99,8'h2d,8'h0f,8'hb0,8'h54,8'hbb,8'h16
  };
  protected bit [7:0] inverse_sbox[256];

  extern function new(string name = "aes_ref_model");
  extern virtual function aes_block_t encrypt(input aes_block_t plaintext, input aes_block_t key);
  extern virtual function aes_block_t decrypt(input aes_block_t ciphertext, input aes_block_t key);
  extern protected virtual function bit [7:0] mul2(input bit [7:0] value);
  extern protected virtual function bit [7:0] mul3(input bit [7:0] value);
  extern protected virtual function bit [7:0] mul9(input bit [7:0] value);
  extern protected virtual function bit [7:0] mul11(input bit [7:0] value);
  extern protected virtual function bit [7:0] mul13(input bit [7:0] value);
  extern protected virtual function bit [7:0] mul14(input bit [7:0] value);
  extern protected virtual function void expand_key(
    input aes_block_t key, output bit [31:0] words[AES_KEY_WORDS]);
  extern protected virtual function void add_round_key(
    ref aes_state_t state,
    input bit [31:0] words[AES_KEY_WORDS],
    input int round_number);
  extern protected virtual function void sub_bytes(
    ref aes_state_t state, input bit inverse);
  extern protected virtual function void shift_rows(
    ref aes_state_t state, input bit inverse);
  extern protected virtual function void mix_columns(
    ref aes_state_t state, input bit inverse);
  extern protected virtual function void block_to_state(
    input aes_block_t block, output aes_state_t state);
  extern protected virtual function aes_block_t state_to_block(
    input aes_state_t state);

endclass : aes_ref_model

function aes_ref_model::new(string name = "aes_ref_model");
  super.new(name);
  foreach(SBOX[i]) inverse_sbox[SBOX[i]] = i[7:0];
endfunction : new

function bit [7:0] aes_ref_model::mul2(input bit [7:0] value);
  if (value[7])
    return (value << 1) ^ 8'h1b;
  else
    return value << 1;
endfunction : mul2

function bit [7:0] aes_ref_model::mul3(input bit [7:0] value);
  return mul2(value) ^ value;
endfunction : mul3

function bit [7:0] aes_ref_model::mul9(input bit [7:0] value);
  return mul2(mul2(mul2(value))) ^ value;
endfunction : mul9

function bit [7:0] aes_ref_model::mul11(input bit [7:0] value);
  return mul2(mul2(mul2(value))) ^ mul2(value) ^ value;
endfunction : mul11

function bit [7:0] aes_ref_model::mul13(input bit [7:0] value);
  return mul2(mul2(mul2(value))) ^ mul2(mul2(value)) ^ value;
endfunction : mul13

function bit [7:0] aes_ref_model::mul14(input bit [7:0] value);
  return mul2(mul2(mul2(value))) ^ mul2(mul2(value)) ^ mul2(value);
endfunction : mul14

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
      temp = {SBOX[temp[23:16]], SBOX[temp[15:8]], SBOX[temp[7:0]], SBOX[temp[31:24]]};
      temp ^= {rcon, 24'b0};
      rcon = mul2(rcon);
    end
    words[i] = words[i-4] ^ temp;
  end
endfunction : expand_key

function void aes_ref_model::add_round_key(
  ref aes_state_t state,
  input bit [31:0] words[AES_KEY_WORDS],
  input int round_number);
  for(int column = 0; column < AES_COLUMNS; column++) begin
    for(int row = 0; row < AES_ROWS; row++) begin
      state[row][column] ^= words[4*round_number+column][31-8*row -: 8];
    end
  end
endfunction : add_round_key

function void aes_ref_model::sub_bytes(
  ref aes_state_t state, input bit inverse);
  foreach(state[row, column]) begin
    state[row][column] = inverse ? inverse_sbox[state[row][column]] :
                                   SBOX[state[row][column]];
  end
endfunction : sub_bytes

function void aes_ref_model::shift_rows(
  ref aes_state_t state, input bit inverse);
  aes_state_t previous;
  previous = state;
  for(int row = 0; row < AES_ROWS; row++) begin
    for(int column = 0; column < AES_COLUMNS; column++) begin
      if (inverse)
        state[row][column] =
          previous[row][(column + AES_COLUMNS - row) % AES_COLUMNS];
      else
        state[row][column] =
          previous[row][(column + row) % AES_COLUMNS];
    end
  end
endfunction : shift_rows

function void aes_ref_model::mix_columns(
  ref aes_state_t state, input bit inverse);
  bit [7:0] a;
  bit [7:0] b;
  bit [7:0] c;
  bit [7:0] d;
  for(int column = 0; column < AES_COLUMNS; column++) begin
    a = state[0][column];
    b = state[1][column];
    c = state[2][column];
    d = state[3][column];
    if(inverse) begin
      state[0][column] = mul14(a)^mul11(b)^mul13(c)^mul9(d);
      state[1][column] = mul9(a)^mul14(b)^mul11(c)^mul13(d);
      state[2][column] = mul13(a)^mul9(b)^mul14(c)^mul11(d);
      state[3][column] = mul11(a)^mul13(b)^mul9(c)^mul14(d);
    end
    else begin
      state[0][column] = mul2(a)^mul3(b)^c^d;
      state[1][column] = a^mul2(b)^mul3(c)^d;
      state[2][column] = a^b^mul2(c)^mul3(d);
      state[3][column] = mul3(a)^b^c^mul2(d);
    end
  end
endfunction : mix_columns

function void aes_ref_model::block_to_state(
  input aes_block_t block, output aes_state_t state);
  for (int column = 0; column < AES_COLUMNS; column++) begin
    for (int row = 0; row < AES_ROWS; row++) begin
      state[row][column] = block[127-8*(4*column+row) -: 8];
    end
  end
endfunction : block_to_state

function aes_block_t aes_ref_model::state_to_block(
  input aes_state_t state);
  aes_block_t block;
  for (int column = 0; column < AES_COLUMNS; column++) begin
    for (int row = 0; row < AES_ROWS; row++) begin
      block[127-8*(4*column+row) -: 8] = state[row][column];
    end
  end
  return block;
endfunction : state_to_block

function aes_block_t aes_ref_model::encrypt(input aes_block_t plaintext, input aes_block_t key);
  aes_state_t state;
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
  aes_state_t state;
  bit [31:0] words[AES_KEY_WORDS];
  expand_key(key, words);
  block_to_state(ciphertext, state);
  add_round_key(state, words, AES_ROUNDS);
  for(int round_number = AES_ROUNDS-1; round_number > 0; round_number--) begin
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
