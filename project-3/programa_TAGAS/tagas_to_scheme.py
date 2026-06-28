import re
import txt_colors as c

PALAVRAS_RESERVADAS= ["add", "remove", "path", "cycle", "print", "undo", ">", "<>", "exit"]

labels = {}

# teste
def main():
    print("Teste de processamento tagas to scheme!\n")
    while True:
        x = input("# ")
        scheme_command, must_run, msgs = tagas_to_scheme(x)
        for msg in msgs:
            print(msg)
        print(f"(must_run: {must_run})")
        print(f"------> {scheme_command}")

def tagas_to_scheme(tagas_line):
    """
    Traduz uma linha de TAGAS para scheme.
    """

    msgs = []

    # lógica labels
    c_line = process_labels(tagas_line, msgs)
    if c_line is None:
        return None, False, msgs

    # lógica espaços
    c_line = process_spaces(c_line, msgs)

    return f"(execute {c_line})", True, msgs

def process_spaces(line, msgs):
    linha_espacada = re.sub(r'(<>|>)', r' \1 ', line)
    
    return " ".join(linha_espacada.split())

def save_label(title, content, msgs):
    global labels
    update = title in labels.keys()
    labels[title] = content
    msgs.append(f"Label '{title}' {('atualizada.' if update else 'criada.')}\n")

def replace_labels(line, msgs):
    global labels
    for label, content in labels.items():
        line = line.replace(label, content)
    return line

def process_labels(tagas_line, msgs):
    if ":" in tagas_line:
        parts = tagas_line.split(":")
        title = parts[0]
        if " " in title:
            msgs.append("[ERRO] Labels não podem conter espaços (mal uso de ':').\n")
        elif len(parts) > 2:
            msgs.append("[ERRO] Mal uso de ':' (só pode haver UMA ocorrência de ':' indicando a criação de uma label).\n")
        elif title in PALAVRAS_RESERVADAS:
            msgs.append(f"[ERRO] '{title}' é uma palavra reservada que NÃO pode ser usada como label.\n")
        else:
            # label válida para ser criada
            save_label(parts[0], parts[1], msgs)
        return None  # Não precisa rodar nada de scheme
        
    # replace das labels pelos contents
    return replace_labels(tagas_line, msgs)

if __name__ == "__main__":
    main()