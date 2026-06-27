import subprocess

import subprocess

def start_racket_process():
    """
    Inicia o processo do Racket em background.
    """
    process = subprocess.Popen(
        ['racket', '-I', 'racket', '-f', 'setup.rkt', '-i'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1 
    )
    
    end_steup_msg = "#&__END_SETUP__&#"
    process.stdin.write('(setup)\n')
    process.stdin.write(f'(display "{end_steup_msg}") (newline)\n')
    process.stdin.flush()

    while True:
        linha = process.stdout.readline()
        if end_steup_msg in linha:
            break

    return process

def tagas_to_scheme(tagas_line, end_msg=""):
    """
    Traduz uma linha de TAGAS para scheme.
    """
    partes = tagas_line.split()
    
    # lógica labels

    # possíveis adaptações mais complicadas

    # ...

    return f"({tagas_line}) (newline) {"" if end_msg == "" else f'(display \"{end_msg}\") (newline)'} (flush-output)\n"  

def main():

    scheme_process = start_racket_process();

    print("------------------")
    print("Bem-vindo ao terminal TAGAS!")
    print("Digite 'exit' para sair.\n")
    print("------------------")
    
    while True:

        tagas_line = input("# ")
        
        if tagas_line.strip().lower() == "exit":
            scheme_process.stdin.close()
            scheme_process.terminate()
            print("Encerrando...")
            break
            
        end_msg = "#&__FIM__&#"
        scheme_line = tagas_to_scheme(tagas_line, end_msg)
        
        if not scheme_line:
            print("[Erro] Sintaxe inválida.\n")
            continue
        
        
        # Envia para o processo do Racket
        scheme_process.stdin.write(scheme_line)
        scheme_process.stdin.flush() 
        
        # Lê a e printa resposta
        while True:
            linha = scheme_process.stdout.readline()
            if end_msg in linha:
                break

            # print linha:
            print(f"-> {linha.strip()}")

if __name__ == "__main__":
    main()