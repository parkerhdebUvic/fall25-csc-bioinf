# week1/code/code_codon/dbg.py
# Codon-friendly: no matplotlib, no typing module, no Optional/None for fields that later hold ints.

def reverse_complement(key: str) -> str:
    complement = {'A': 'T', 'T': 'A', 'G': 'C', 'C': 'G'}
    r = []
    for ch in key[::-1]:
        r.append(complement.get(ch, ch))
    return ''.join(r)


class Node:
    def __init__(self, kmer: str):
        # children are indices (ints). Seed and clear to lock element type to int.
        s = set()
        s.add(-1)      # seed with int to fix element type
        s.clear()
        self._children = s   # set of int

        self._count = 0
        self.kmer = kmer
        self.visited = False
        self.depth = 0
        # use -1 instead of None so the type stays int throughout
        self.max_depth_child = -1

    def add_child(self, child_idx: int) -> None:
        self._children.add(child_idx)

    def increase(self) -> None:
        self._count += 1

    def reset(self) -> None:
        self.visited = False
        self.depth = 0
        self.max_depth_child = -1

    def get_count(self) -> int:
        return self._count

    def get_children(self):
        return list(self._children)

    def remove_children(self, target_set):
        self._children = self._children - target_set


class DBG:
    def __init__(self, k: int, data_list):
        self.k = k

        # dicts with explicit value types:
        # seed & delete to force key/value types without keeping entries
        self.nodes = {}
        self.nodes[0] = Node("A" * k)  # seed
        del self.nodes[0]

        self.kmer2idx = {}
        self.kmer2idx["$"] = -1        # seed
        del self.kmer2idx["$"]

        self.kmer_count = 0
        self._check(data_list)
        self._build(data_list)

    def _check(self, data_list):
        assert len(data_list) > 0
        assert len(data_list[0]) > 0
        assert self.k <= len(data_list[0][0])

    def _build(self, data_list):
        for data in data_list:
            for original in data:
                rc = reverse_complement(original)
                # keep original behavior (-1) to match reference repo
                for i in range(len(original) - self.k - 1):
                    self._add_arc(original[i: i + self.k],
                                  original[i + 1: i + 1 + self.k])
                    self._add_arc(rc[i: i + self.k], rc[i + 1: i + 1 + self.k])

    def show_count_distribution(self):
        count = [0] * 30
        for idx in self.nodes:
            c = self.nodes[idx].get_count()
            if 0 <= c < len(count):
                count[c] += 1
        print(count[0:10])

    def _add_node(self, kmer: str) -> int:
        if kmer not in self.kmer2idx:
            self.kmer2idx[kmer] = self.kmer_count
            self.nodes[self.kmer_count] = Node(kmer)
            self.kmer_count += 1
        idx = self.kmer2idx[kmer]
        self.nodes[idx].increase()
        return idx

    def _add_arc(self, kmer1: str, kmer2: str) -> None:
        idx1 = self._add_node(kmer1)
        idx2 = self._add_node(kmer2)
        self.nodes[idx1].add_child(idx2)

    def _get_count(self, child_idx: int) -> int:
        return self.nodes[child_idx].get_count()

    def _get_sorted_children(self, idx: int):
        children = self.nodes[idx].get_children()
        children.sort(key=self._get_count, reverse=True)
        return children

    # def _get_depth(self, idx: int) -> int:
    #     if not self.nodes[idx].visited:
    #         self.nodes[idx].visited = True
    #         children = self._get_sorted_children(idx)
    #         max_depth = 0
    #         max_child = -1
    #         for child in children:
    #             depth = self._get_depth(child)
    #             if depth > max_depth:
    #                 max_depth, max_child = depth, child
    #         self.nodes[idx].depth = max_depth + 1
    #         self.nodes[idx].max_depth_child = max_child
    #     return self.nodes[idx].depth

    def _get_depth(self, idx: int) -> int:
        # Iterative DFS to avoid recursion/stack overflows on deep graphs.
        # Two-phase: push (node,0) on entry, then (node,1) to compute depth after children.
        stack = [(idx, 0)]
        while stack:
            node, state = stack.pop()
            n = self.nodes[node]

            if state == 0:
                if n.visited:
                    continue
                n.visited = True
                # schedule exit
                stack.append((node, 1))
                # visit children (heaviest first)
                for child in self._get_sorted_children(node):
                    if not self.nodes[child].visited:
                        stack.append((child, 0))
            else:
                # compute depth from children already processed
                max_depth = 0
                max_child = -1
                for child in self._get_sorted_children(node):
                    d = self.nodes[child].depth
                    if d > max_depth:
                        max_depth = d
                        max_child = child
                n.depth = max_depth + 1
                n.max_depth_child = max_child

        return self.nodes[idx].depth

    def _reset(self) -> None:
        for idx in list(self.nodes.keys()):
            self.nodes[idx].reset()

    def _get_longest_path(self):
        max_depth = 0
        max_idx = -1
        for idx in self.nodes.keys():
            depth = self._get_depth(idx)
            if depth > max_depth:
                max_depth, max_idx = depth, idx

        path = []
        while max_idx != -1:
            path.append(max_idx)
            max_idx = self.nodes[max_idx].max_depth_child
        return path

    def _delete_path(self, path) -> None:
        for idx in path:
            del self.nodes[idx]
        path_set = set(path)
        for idx in list(self.nodes.keys()):
            self.nodes[idx].remove_children(path_set)

    def _concat_path(self, path):
        if len(path) < 1:
            return None
        concat = self.nodes[path[0]].kmer
        for i in range(1, len(path)):
            concat += self.nodes[path[i]].kmer[-1]
        return concat

    def get_longest_contig(self):
        self._reset()
        path = self._get_longest_path()
        contig = self._concat_path(path)
        self._delete_path(path)
        return contig
