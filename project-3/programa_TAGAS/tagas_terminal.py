import subprocess
import sys
import tagas_to_scheme as tagas
import txt_colors as c
import multiprocessing, queue, draw

END_MSG = "#&__FIM__&#"
END_SETUP_MSG = "#&__END_SETUP__&#"
DRAW_MSG = "[#&__DRAW__&#]"

debug_mode = False
draw_mode = False

def main():
    global debug_mode, draw_mode

    if ("--debug" in sys.argv):
        debug_mode = True
        print("Modo debug ativado.")
        debug_log("Iniciando processo do Racket...")

    draw_queue = None
    if ("--draw" in sys.argv or "-d" in sys.argv):
        draw_mode = True

        draw_queue = multiprocessing.Queue()
        draw_process = multiprocessing.Process(target=draw.run_drawer, args=(draw_queue, debug_log))
        draw_process.daemon = True
        draw_process.start()

        debug_log("Processo DRAW inciado!")
        print("Modo draw ativo!")

    else:
        print("Modo draw está desligado. Para ativá-lo, inicie com \"--draw\" ou \"-d\".")

    scheme_process = start_racket_process()

    print("------------------")
    print("Bem-vindo ao terminal TAGAS!")
    print("Digite 'exit' para sair.")
    print("------------------")
    
    try:
        main_loop(scheme_process, draw_queue)
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
        if draw_mode:
            draw_queue.put("STOP")
            if draw_process.is_alive():
                debug_log("TERMINATING DRAWER")
                draw_process.terminate()
            draw_process.join()
            draw_process.close()

def debug_log(msg):
    global debug_mode
    if debug_mode:
        print(f"{c.BLUE}[DEBUG] :: {msg}{c.RESET}")

def start_racket_process():
    """
    Inicia o processo do Racket em background.
    """
    global draw_mode

    process = subprocess.Popen(
        # TODO: Ajuste o caminho dos arquivos para contexto da localização do app
        ['racket', '-I', 'racket', '-f', 'scheme\\setup.rkt', '-f', 'scheme\\tagas.rkt', '-i'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        encoding='utf-8'
    )

    process.stdin.write('(setup)\n')

    if draw_mode:
        process.stdin.write(f'(set-draw-mode! #t "{DRAW_MSG}")\n')

    process.stdin.write(f'(display "{END_SETUP_MSG}") (newline)\n')
    process.stdin.flush()

    while True:
        linha = process.stdout.readline()
        if END_SETUP_MSG in linha:
            break

        debug_log(linha)

    return process

def main_loop(scheme_process, draw_queue):
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
            scheme_command, must_run, msgs = tagas.tagas_to_scheme(tagas_line)

            for msg in msgs:
                print_result(msg)
        
            if not must_run or scheme_command is None:
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
            
            if DRAW_MSG in linha:
                draw_queue.put(linha[len(DRAW_MSG):])
            else:
                # print linha:
                print_result(linha)
            

def print_result(linha):

    if "[DEBUG]" in linha:
        debug_log(linha.replace("[DEBUG]", "").strip())
    elif "[ERRO]" in linha:
        print(f"{c.RED}{linha.strip()}{c.RESET}")
    elif "[WARNING]" in linha:
        print(f"{c.YELLOW}{linha.strip()}{c.RESET}")
    else:
        print(f"-> {linha.strip()}")

if __name__ == "__main__":
    main()