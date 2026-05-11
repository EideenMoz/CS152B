#include "xil_printf.h"
#include "xgpio.h"
#include "xparameters.h"

char buffer[32];

void read_line(char *buf, int max_len) {
    int i = 0;
    char c;

    while (i < max_len - 1) {
        c = inbyte();  // read from UART
        if (c == '\r' || c == '\n') break;
        buf[i++] = c;
    }
    buf[i] = '\0';
}

int parse_u32_pair(const char *s, int *a, int *b) {
    int i = 0;

    *a = 0;
    *b = 0;

    // parse first number
    while (s[i] >= '0' && s[i] <= '9') {
        *a = (*a) * 10 + (s[i] - '0');
        i++;
    }

    if (s[i] != '/') return 0;
    i++;

    // parse second number
    while (s[i] >= '0' && s[i] <= '9') {
        *b = (*b) * 10 + (s[i] - '0');
        i++;
    }

    return 1;
}

int main() {
    XGpio gpio;
    int n1, n2;
    int result;

    // Initialize GPIO (use correct device ID from xparameters.h)
    XGpio_Initialize(&gpio, XPAR_AXI_GPIO_0_DEVICE_ID);

    // Channel 2 = LEDs (output)
    XGpio_SetDataDirection(&gpio, 2, 0x00000000);

    // Channel 1 = Buttons (input) (not used here but fine to keep)
    XGpio_SetDataDirection(&gpio, 1, 0xFFFFFFFF);

    while (1) {

        read_line(buffer, sizeof(buffer));

        if (!parse_u32_pair(buffer, &n1, &n2)) {
            xil_printf("Invalid format! Use n1/n2\r\n");
            continue;
        }

        result = n1 * n2;

        xil_printf("Result = %d\r\n", result);

        if (result > 100) {
            XGpio_DiscreteWrite(&gpio, 2, 0xFF);  // turn LED ON
        } else {
            XGpio_DiscreteWrite(&gpio, 2, 0x00);  // turn LED OFF
        }
    }

    return 0;
}
