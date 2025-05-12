# Python program for Huffman Coding
import numpy as np
import heapq

class Node:
    def __init__(self, symbol=None, frequency=None):
        self.symbol = symbol
        self.frequency = frequency
        self.left = None
        self.right = None

    def __lt__(self, other):
        return self.frequency < other.frequency

def build_huffman_tree(chars, freq):
  
    # Create a priority queue of nodes
    priority_queue = [Node(char, f) for char, f in zip(chars, freq)]
    heapq.heapify(priority_queue)
    # Build the Huffman tree
    while len(priority_queue) > 1:
        left_child = heapq.heappop(priority_queue)
        right_child = heapq.heappop(priority_queue)
        merged_node = Node(frequency=left_child.frequency + right_child.frequency)
        merged_node.left = left_child
        merged_node.right = right_child
        heapq.heappush(priority_queue, merged_node)

    return priority_queue[0]

def generate_huffman_codes(node, code="", huffman_codes={}):
    if node is not None:
        if node.symbol is not None:
            huffman_codes[node.symbol] = code
        generate_huffman_codes(node.left, code + "1", huffman_codes)
        generate_huffman_codes(node.right, code + "0", huffman_codes)

    return huffman_codes

# Given example
i = 2
chars = ['1', '2', '3', '4', '5', '6']
numbers = np.loadtxt(f'pattern{i}.dat', dtype=int)
freq = [np.sum(numbers == 1), np.sum(numbers == 2), np.sum(numbers == 3), np.sum(numbers == 4), np.sum(numbers == 5), np.sum(numbers == 6)]
print(freq)
# Build the Huffman tree
root = build_huffman_tree(chars, freq)

# Generate Huffman codes
huffman_codes = generate_huffman_codes(root)
golden = np.loadtxt(f'golden{i}.dat', dtype=str)
print("Golden Result")
for i in range(6,12):
    print(f"Character: {i-5}, Code: ",bin(int(golden[i][0], 16))[2:])
print("Python Result")

# Print Huffman codes
for i in range(0,6):
    c = f"{i+1}"
    code = huffman_codes[c]
    print(f"Character: {i+1}, Code: {code}")
