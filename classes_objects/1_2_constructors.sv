class Packet;
    logic [7:0] addr;
    logic [7:0] data;
    int length;

    function new (logic [7:0] a =0, logic [7:0] d=0);
        addr = a;
        data = d;
    endfunction
endclass


module top;
    initial begin
        Packet p1 = new();
        Packet p2 = new(8'hFF, 8'hAA);
        $display("p1.addr=%0h p2.addr=%0h", p1.addr, p2.addr);
        $finish;
    end
endmodule