class Packet;
    logic [7:0] addr;
    logic [7:0] data;
    int length;

    function void print();
        $display("addr=%0h  data=%0h", addr, data);
    endfunction
endclass

module top;
    initial begin
        Packet p;       // handle - currently null
        p = new();      // allocate object
        p.addr = 8'hAB;
        p.data = 8'h55;
        p.print();
        $finish;
    end
endmodule
