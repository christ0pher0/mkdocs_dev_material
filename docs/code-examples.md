```py title="add numbers" linenums="1"
# Function to add two numbers
def add_two_numbers(num1, num2):
  return num1 + num2

# Example usage
result = add_two_numbers(5, 3)
print('The sum is:', result)
```
```js title="code-examples.md" linenums="1" hl_lines="2-4"
// Function to concatenate two strings
function concatenateStrings(str1, str2) {
  return str1 + str2;
}

// Example usage
const result = concatenateStrings("Hello, ", "World!");
console.log("The concatenated string is:", result);
```

### Multiplying Numbers with `bc`

You can use the `bc` command-line calculator to perform arithmetic in the terminal. Here's how to multiply two numbers:

```bash title="Multiply 4 by 16 using bc"
echo "4 * 16" | bc
```

This command sends the expression `4 * 16` to `bc`, which evaluates it and returns `64`.

### `masscan` examples

```bash title="Scan Port 80 on a Subnet with masscan"
sudo masscan 192.168.1.0/24 -p80
```

```bash title="Scan Multiple Ports"
sudo masscan 192.168.1.0/24 -p22,80,443
```

```bash title="Limit Scan Rate"
sudo masscan 192.168.1.0/24 -p80 --rate=1000
```

```bash title="Scan a Single IP"
sudo masscan 192.168.1.100 -p1-1000
```

```bash title="Output to XML"
sudo masscan 192.168.1.0/24 -p80 -oX results.xml
```

```bash title="Scan for DNS Servers (TCP 53)"
sudo masscan 192.168.1.0/24 -p53 --rate=500
```


