import re

PALAVRAS_RESERVADAS= ["add", "remove", "path", "cycle", "print", "undo"]

def main():
    print("Teste de processamento tagas to scheme!\n")
    while True:
        x = input("# ")
        print("-> ", process_spaces(x))

def process_spaces(line):
    linha_espacada = re.sub(r'(<>|>)', r' \1 ', line)
    
    return " ".join(linha_espacada.split())

labels = {}

def save_label(title, content):
    global labels
    update = title in labels.keys()
    labels[title] = content
    print(f"Label '{title}' {('atualizada.' if update else 'criada.')}")

def replace_labels(line):
    global labels
    for label, content in labels.items():
        line = line.replace(label, content)
    return line

def process_labels(tagas_line):
    if ":" in tagas_line:
        parts = tagas_line.split(":")
        title = parts[0]
        if " " in title:
            print("[Erro] Labels não podem conter espaços (mal uso de ':').\n")
        elif len(parts) > 2:
            print("[Erro] Mal uso de ':' (só pode haver UMA ocorrência de ':' indicando a criação de uma label).\n")
        elif title in PALAVRAS_RESERVADAS:
            print(f"[Erro] '{title}' é uma palavra reservada que NÃO pode ser usada como label.\n")
        else:
            # label válida para ser criada
            save_label(parts[0], parts[1])
        return None  # Não precisa rodar nada de scheme
        
    # replace das labels pelos contents
    return replace_labels(tagas_line)

def tagas_to_scheme(tagas_line):
    """
    Traduz uma linha de TAGAS para scheme.
    """

    # lógica labels
    c_line = process_labels(tagas_line)
    if c_line is None:
        return None, False

    # lógica espaços
    c_line = process_spaces(c_line)

    return f"(execute {c_line})", True

if __name__ == "__main__":
    main()