import subprocess
import sys
import tagas_to_scheme as tagas

END_MSG = "#&__FIM__&#"
END_SETUP_MSG = "#&__END_SETUP__&#"

def debug_log(msg):
    global debug_mode
    if debug_mode:
        print("[DEBUG] :: ", msg)

def start_racket_process():
    """
    Inicia o processo do Racket em background.
    """
    process = subprocess.Popen(
        # TODO: Ajuste o caminho dos arquivos para contexto da localização do app
        ['racket', '-I', 'racket', '-f', 'scheme\\setup.rkt', '-f', 'scheme\\tagas.rkt', '-i'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1 
    )

    process.stdin.write('(setup)\n')
    process.stdin.write(f'(display "{END_SETUP_MSG}") (newline)\n')
    process.stdin.flush()

    while True:
        linha = process.stdout.readline()
        if END_SETUP_MSG in linha:
            break

        debug_log(linha)

    return process

def main_loop(scheme_process):
    global debug_mode

    while True:
        tagas_line = input("# ")
        
        # ignora linha vazia
        if tagas_line.strip() == "":
            continue
        
        # comando exit
        if tagas_line.strip().lower() == "exit":
            print("-> Comando EXIT recebido.")
            break
        
        # comando principal que será rodado no scheme, não é para chegar até o final assim
        scheme_command = "(display \"[ERRO] Comando não capturado pelo terminal!\")"

        # modo debug, permite rodar comandos scheme cru
        if debug_mode and tagas_line.strip().lower() == "scheme":
            scheme_command = input("(SCHEME CRU) # ")
        
        # interpretação TAGAS -> Scheme
        else:
            scheme_command, must_run = tagas.tagas_to_scheme(tagas_line)
        
            if not must_run:
                continue
            if scheme_command is None:
                print("[Erro] Sintaxe inválida. Motivo desconhecido.\n")
                continue
        
        # linha completa que será enviada para o processo do Racket
        full_running_line = f"{scheme_command} (newline) (display \"{END_MSG}\") (newline) (flush-output)\n"
        
        # envia para o processo do Racket
        scheme_process.stdin.write(full_running_line)
        scheme_process.stdin.flush() 
        
        # lê a e printa resposta
        while True:
            linha = scheme_process.stdout.readline()
            if END_MSG in linha:
                break

            # print linha:
            print(f"-> {linha.strip()}")

def main():
    global debug_mode
    debug_mode = False

    if ("--debug" in sys.argv):
        debug_mode = True
        print("Modo debug ativado.")
        debug_log("Iniciando processo do Racket...")

    scheme_process = start_racket_process()

    print("------------------")
    print("Bem-vindo ao terminal TAGAS!")
    print("Digite 'exit' para sair.")
    print("------------------")
    
    try:
        main_loop(scheme_process)
    except KeyboardInterrupt:
        print("\nPrograma interrompido pelo usuário (Ctrl+C).")
        
    except Exception as e:
        # Captura qualquer outro erro maluco que o seu código Python possa dar
        print(f"\n[Erro Crítico]\n {e}\n\n____________")
    finally:
        scheme_process.stdin.close()
        scheme_process.terminate()
        print("Encerrando o programa...")
        scheme_process.wait()

if __name__ == "__main__":
    main()