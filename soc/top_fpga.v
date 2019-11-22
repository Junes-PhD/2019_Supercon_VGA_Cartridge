/*
Top module for FPGA. Essentially instantiates the SOC and adds the FPGA-specific things like
PLL, tristate buffers etc needed to interface with the hardware.
*/
/*
 * Copyright (C) 2019  Jeroen Domburg <jeroen@spritesmods.com>
 * All rights reserved.
 *
 * BSD 3-clause, see LICENSE.bsd
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


module top_fpga(
		input clk, 
		input [7:0] btn, 
`ifdef BADGE_V3
		output [10:0] ledc,
		output [2:0] leda,
//		inout [29:0] genio,
`elsif BADGE_PROD
		output [9:0] ledc,
		output [2:0] leda,
//		inout [29:0] genio,
`else
		output [8:0] led,
//		inout [27:0] genio,
`endif
		output uart_tx,
		input uart_rx,
`ifdef BADGE_V3
		output irda_tx,
		input irda_rx,
		output irda_sd,
`elsif BADGE_PROD
		output irda_tx,
		input irda_rx,
		output irda_sd,
`endif
		output pwmout,
		output [17:0] lcd_db,
		output lcd_rd,
		output lcd_wr,
		output lcd_rs,
		output lcd_cs,
		input lcd_id,
		output lcd_rst,
		input lcd_fmark,
		output lcd_blen,
		output psrama_nce,
		output psrama_sclk,
		inout [3:0] psrama_sio,
		output psramb_nce,
		output psramb_sclk,
		inout [3:0] psramb_sio,
		output flash_cs,
		inout flash_miso,
		inout flash_mosi,
		inout flash_wp,
		inout flash_hold,
		output fsel_d,
		output fsel_c,
		output programn,
		
		output vga_hsync,
		output vga_vsync,
		output [7:0] vga_red,
		output [7:0] vga_green,
		output [7:0] vga_blue,
		output genio25_dupe,
		output genio26_dupe,
		output genio29_dupe,
		
		output [3:0] gpdi_dp, gpdi_dn,
		inout usb_dp,
		inout usb_dm,
		output usb_pu,
		input usb_vdet,

		inout [5:0] sao1,
		inout [5:0] sao2,
		inout [7:0] pmod,

		output adcrefout,
		input adcref4
	);
	
	// each of these cartridge port IOs are connected to two different BGA balls.
	// tri-state these duped pins to prevent conflict with the other ones.
	assign genio25_dupe = 1'bz;
	assign genio26_dupe = 1'bz;
	assign genio29_dupe = 1'bz;
	
	wire adc4;
	assign adc4 = ~adcref4;

	wire clk24m;
	wire clk48m;
	wire clk96m;
	wire rst_soc;

	wire clkint;
	OSCG #(
		.DIV(8) //155MHz by default... this divides it down to 19MHz.
	) oscint (
		.OSC(clkint)
	);

	wire vid_pixelclk;
	wire vid_fetch_next;
	wire vid_next_line;
	wire vid_next_field;
	wire [7:0] vid_red;
	wire [7:0] vid_green;
	wire [7:0] vid_blue;


	reg [31:0] jdreg_done;
	reg jdsel_done;
	reg jdreg_update;
	wire [31:0] jdreg_send;

	wire [3:0] flash_sout;
	wire [3:0] flash_sin;
	wire flash_oe;
	wire flash_bus_qpi;
	wire flash_sclk;
	wire flash_cs;
	wire flash_selected;
	//wire [29:0] genio_in;
	//wire [29:0] genio_out;
	//wire [29:0] genio_oe;
	wire [5:0] sao1_in;
	wire [5:0] sao1_out;
	wire [5:0] sao1_oe;
	wire [5:0] sao2_in;
	wire [5:0] sao2_out;
	wire [5:0] sao2_oe;
	wire [7:0] pmod_in;
	wire [7:0] pmod_out;
	wire [7:0] pmod_oe;

	wire clkint;

`ifdef BADGE_V3
	wire [9:0] led;

	ledctl ledctl_inst (
		.clk(clk),
		.rst(0),
		.ledc(ledc),
		.leda(leda),
		.led(led)
	);
`elsif BADGE_PROD
	wire [8:0] led;
	assign ledc = led;
	assign leda = 3'b1;
`endif

	soc soc (
		.clk24m(clk24m),
		.clk48m(clk48m),
		.clk96m(clk96m),
		.clkint(clkint),
		.rst(rst_soc),
		.btn(btn),
		.led(led),
		.uart_tx(uart_tx),
		.uart_rx(uart_rx),

`ifdef BADGE_V3
		.irda_tx(irda_tx),
		.irda_rx(irda_rx),
		.irda_sd(irda_sd),
`elsif BADGE_PROD
		.irda_tx(irda_tx),
		.irda_rx(irda_rx),
		.irda_sd(irda_sd),
`endif

		.pwmout(pwmout),
		.lcd_db(lcd_db),
		.lcd_rd(lcd_rd),
		.lcd_wr(lcd_wr),
		.lcd_rs(lcd_rs),
		.lcd_cs(lcd_cs),
		.lcd_id(lcd_id),
		.lcd_rst(lcd_rst),
		.lcd_fmark(lcd_fmark),
		.lcd_blen(lcd_blen),
		.psrama_sio(psrama_sio),
		.psrama_nce(psrama_nce),
		.psrama_sclk(psrama_sclk),
		.psramb_sio(psramb_sio),
		.psramb_nce(psramb_nce),
		.psramb_sclk(psramb_sclk),
		.flash_nce(flash_cs),
		.flash_selected(flash_selected),
		.flash_sclk(flash_sclk),
		.flash_sin(flash_sin),
		.flash_sout(flash_sout),
		.flash_oe(flash_oe),
		.flash_bus_qpi(flash_bus_qpi),
		.fsel_d(fsel_d),
		.fsel_c(fsel_c),
		.programn(programn),

		.vid_pixelclk(vid_pixelclk),
		.vid_fetch_next(vid_fetch_next),
		.vid_red(vid_red),
		.vid_green(vid_green),
		.vid_blue(vid_blue),
		.vid_next_line(vid_next_line),
		.vid_next_field(vid_next_field),

		.dbgreg_out(jdreg_send),
		.dbgreg_in(jdreg_done),
		.dbgreg_strobe(jdreg_update),
		.dbgreg_sel(jdsel_done), //0 for IR 0x32, 1 for IR 0x38

		.usb_dp(usb_dp),
		.usb_dn(usb_dm),
		.usb_pu(usb_pu),
		.usb_vdet(usb_vdet),

		.adcrefout(adcrefout),
		.adc4(adc4),

		//.genio_in(genio_in),
		//.genio_out(genio_out),
		//.genio_oe(genio_oe),
		.sao1_in(sao1_in),
		.sao1_out(sao1_out),
		.sao1_oe(sao1_oe),
		.sao2_in(sao2_in),
		.sao2_out(sao2_out),
		.sao2_oe(sao2_oe),
		.pmod_in(pmod_in),
		.pmod_out(pmod_out),
		.pmod_oe(pmod_oe)
	);

	sysmgr sysmgr_I (
		.clk_in(clk),
		.rst_in(1'b0),
		.clk_24m(clk24m),
		.clk_48m(clk48m),
		.clk_96m(clk96m),
		.rst_out(rst_soc)
	);

	hdmi_encoder hdmi_encoder(
		.clk_8m(clk),
		.gpdi_dp(gpdi_dp),
		.gpdi_dn(gpdi_dn),

		.pixelclk(vid_pixelclk),
		.fetch_next(vid_fetch_next),
		.red(vid_red),
		.green(vid_green),
		.blue(vid_blue),
		.hsync(vga_hsync),
		.vsync(vga_vsync),
		.vga_red(vga_red),
		.vga_green(vga_green),
		.vga_blue(vga_blue),
		.next_line(vid_next_line),
		.next_field(vid_next_field),
	);

	genvar i;

	TRELLIS_IO #(.DIR("BIDIR")) flash_tristate_mosi (.I(flash_sout[0]),.T(flash_bus_qpi && !flash_oe),.B(flash_mosi),.O(flash_sin[0]));
	TRELLIS_IO #(.DIR("BIDIR")) flash_tristate_miso (.I(flash_sout[1]),.T(!flash_bus_qpi || !flash_oe),.B(flash_miso),.O(flash_sin[1]));
	TRELLIS_IO #(.DIR("BIDIR")) flash_tristate_wp (.I(flash_sout[2]),.T(flash_bus_qpi && !flash_oe),.B(flash_wp),.O(flash_sin[2]));
	TRELLIS_IO #(.DIR("BIDIR")) flash_tristate_hold (.I(flash_sout[3]),.T(flash_bus_qpi && !flash_oe),.B(flash_hold),.O(flash_sin[3]));

/*
`ifdef BADGE_V3
	for (i=0; i<30; i++) begin
`elsif BADGE_PROD
	for (i=0; i<30; i++) begin
`else
	assign genio_in[29] = 0;
	assign genio_in[28] = 0;
	for (i=0; i<28; i++) begin
`endif
		TRELLIS_IO #(.DIR("BIDIR")) genio_tristate[i] (.B(genio[i]), .I(genio_out[i]), .O(genio_in[i]), .T(!genio_oe[i]));
	end


	for (i=0; i<6; i++) begin
		TRELLIS_IO #(.DIR("BIDIR")) sao1_tristate[i] (.B(sao1[i]), .I(sao1_out[i]), .O(sao1_in[i]), .T(!sao1_oe[i]));
		TRELLIS_IO #(.DIR("BIDIR")) sao2_tristate[i] (.B(sao2[i]), .I(sao2_out[i]), .O(sao2_in[i]), .T(!sao2_oe[i]));
	end

	for (i=0; i<8; i++) begin
		TRELLIS_IO #(.DIR("BIDIR")) pmod_tristate[i] (.B(pmod[i]), .I(pmod_out[i]), .O(pmod_in[i]), .T(!pmod_oe[i]));
	end
*/
	USRMCLK usrmclk_inst (
		.USRMCLKI(flash_sclk),
		.USRMCLKTS(!flash_selected)
	) /* synthesis syn_noprune=1 */;

	//Note: JTAG specs say we should sample on the rising edge of TCK. However, the LA readings show that 
	//this would be cutting it very close wrt sample/hold times... what's wise here?
	//Edit: Rising edge seems not to work. Using falling edge instead.
	//Note: TDO is not implemented atm.
	wire jtdi, jtck, jshift, jupdate, jce1, jce2, jrstn, jrti1, jrti2;
	JTAGG jtag(
		.JTDI(jtdi), //gets data
		.JTCK(jtck), //clock in
		.JRTI2(jrti1),  //1 if reg is selected and state is r/t idle
		.JRTI1(jrti2),
		.JSHIFT(jshift), //1 if data is shifted in
		.JUPDATE(jupdate), //1 for 1 tck on finish shifting
		.JRSTN(jrstn),
		.JCE2(jce2),  //1 if data shifted into this reg
		.JCE1(jce1)
	);



	//Janky JTAG DR implementation.
	reg oldjshift;
	reg [3:0] tck_shift;
	reg [31:0] jdreg;
	reg jdsel;
	always @(posedge clk48m) begin
		jdreg_update <= 0;
		if (jrstn == 0) begin
			oldjshift <= jshift;
			jdreg <= 0;
			jdsel <= 0;
			tck_shift <= 0;
		end else begin
			tck_shift[3:1] <= tck_shift[2:0];
			tck_shift[0] <= jtck;
			if (tck_shift[3]==0 && tck_shift[2]==1) begin //somewhat after raising edge
				if (oldjshift) begin
					jdreg[30:0] <= jdreg[31:1];
					jdreg[31] <= jtdi;
				end
				if (jce1 || jce2) begin
					jdsel <= jce2;
				end
				if (jupdate) begin
					jdreg_done <= jdreg;
					jdsel_done <= jdsel;
					jdreg_update <= 1;
				end
				oldjshift <= jshift;
			end
		end
	end

endmodule
