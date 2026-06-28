import subprocess
import sys
import tagas_to_scheme as tagas

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
    
    end_steup_msg = "#&__END_SETUP__&#"
    process.stdin.write('(setup)\n')
    process.stdin.write(f'(display "{end_steup_msg}") (newline)\n')
    process.stdin.flush()

    while True:
        linha = process.stdout.readline()
        if end_steup_msg in linha:
            break

        debug_log(linha)

    return process

def main_loop(scheme_process):
    while True:
        tagas_line = input("# ")
        
        if tagas_line.strip().lower() == "exit":
            print("-> Comando EXIT recebido.")
            break
            
        end_msg = "#&__FIM__&#"
        scheme_command, must_run = tagas.tagas_to_scheme(tagas_line)
        
        if not must_run:
            continue

        if scheme_command is None:
            print("[Erro] Sintaxe inválida. Motivo desconhecido.\n")
            continue

        full_running_line = f"({scheme_command}) (newline) (display \"{end_msg}\") (newline) (flush-output)\n"
        
        # Envia para o processo do Racket
        scheme_process.stdin.write(full_running_line)
        scheme_process.stdin.flush() 
        
        # Lê a e printa resposta
        while True:
            linha = scheme_process.stdout.readline()
            if end_msg in linha:
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