import matplotlib.pyplot as plt
import networkx as nx
import re
import multiprocessing, queue

# teste
def main():
    plot_graph("((N) (M N) (F) (E) (D) (C D) (B C A F) (A D C B))")


def get_graph(adjacencies_str):
    g = nx.DiGraph()
    
    # transforma '((A B C) (B D) (E))' na losta ['A B C', 'B D', 'E']
    blocos = re.findall(r'\(([^()]+)\)', adjacencies_str)
    
    for bloco in blocos:
        tokens = bloco.split()
        no_origem = tokens[0]
        g.add_node(no_origem)
        
        for no_destino in tokens[1:]:
            g.add_edge(no_origem, no_destino)
            
    return g

def run_drawer(q: multiprocessing.Queue, debug_log):
    """
    Função que rodará em um processo paralelo.
    Fica escutando a queue e atualiza o grafo quando chegar uma nova string.
    """
    try:
        debug_log("Iniciando drawer_main")
        drawer_main(q)
    except KeyboardInterrupt:
        debug_log("KeyboardInterrupt no DRAWER")

def drawer_main(q: multiprocessing.Queue):
    # modo "atualizável" do matplot
    plt.ion() 
    fig, ax = plt.subplots() #figsize=(6, 6)
    fig.canvas.manager.set_window_title('TAGAS Drawing')

    # O loop roda enquanto a janela do matplotlib não for fechada pelo usuário
    while plt.fignum_exists(fig.number):
        try:
            # Tenta pegar a string de atualização (espera no máximo 0.1s para não travar a tela)
            adjacencies_str = q.get(timeout=0.1)
            
            if adjacencies_str == "STOP":
                break
                
            g = get_graph(adjacencies_str)
            
            # Desenho
            ax.clear()
            ax.set_axis_off()
            
            if len(g.nodes) > 0:
                # Layout
                pos = nx.shell_layout(g) 

                # Desenha os nós
                nx.draw_networkx_nodes(g, pos=pos, node_color="indigo", node_size=500)

                # Desenha as arestas
                nx.draw_networkx_edges(g, pos=pos, arrowstyle="->", arrowsize=20, width=2)

                # Adiciona os nomes dos vértices centralizados nas bolinhas
                nx.draw_networkx_labels(g, pos=pos, font_color="white", font_weight="bold")
            
            plt.draw() # Aplica as mudanças na janela

        except queue.Empty:
            # Se a fila está vazia (nenhum comando novo), só processa os eventos da GUI (ex: mover a janela)
            plt.pause(0.1)

def plot_graph(adjacencies_str):
    '''
    Plota da maneira padrão criando uma janela dedicada ao plot.
    '''
    g = get_graph(adjacencies_str)

    # Layout
    pos = nx.shell_layout(g) 

    # Desenha os nós
    nx.draw_networkx_nodes(g, pos=pos, node_color="indigo", node_size=500)

    # Desenha as arestas
    nx.draw_networkx_edges(g, pos=pos, arrowstyle="->", arrowsize=20, width=2)

    # Adiciona os nomes dos vértices centralizados nas bolinhas
    nx.draw_networkx_labels(g, pos=pos, font_color="white", font_weight="bold")

    ax = plt.gca()
    ax.set_axis_off()
    plt.show()


if __name__ == "__main__":
    main()