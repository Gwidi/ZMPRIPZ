import socket
import constants

# Konfiguracja
HOST = '150.254.46.80'  # Nasłuchuj na wszystkich interfejsach sieciowych
PORT = 1025       # Port komunikacyjny (musi być taki sam w robocie)

# Dane punktów
a = 25
points = [
    (a, 2*a, 0),   # P1
    (2*a, 3*a, 0), # P2
    (3*a, 5*a, 0), # P3
    (4*a, 3*a, 0), # P4
    (5*a, 2*a, 0)  # P5
]

def run_client():
    print(f"Próba połączenia z robotem {HOST}:{PORT}...")
    
    try:
        # Tworzenie gniazda i próba połączenia
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((HOST, PORT))
            print("Połączono z robotem! (Robot jest w PSecond)")
            
            # Pętla wysyłania punktów
            for i, p in enumerate(points):
                # Formatowanie: X,Y,Z
                msg = f"{p[0]:.2f},{p[1]:.2f},{p[2]:.2f}"
                print(f"Wysyłam P{i+1}: {msg}")
                
                s.sendall(msg.encode('utf-8'))
                
                # Czekamy, aż robot dojedzie i odeśle ACK
                response = s.recv(1024).decode('utf-8')
                if "ACK" in response:
                    print(f"Robot osiągnął cel P{i+1}")
                else:
                    print("Błąd: Nieoczekiwana odpowiedź robota.")
                    break
            
            # Zakończenie sekwencji
            print("Wszystkie punkty wysłane. Kończę pracę.")
            s.sendall("STOP".encode('utf-8'))
            time.sleep(1) # Czas na dotarcie pakietu
            
    except ConnectionRefusedError:
        print("Nie można połączyć się z robotem. Upewnij się, że program RAPID jest uruchomiony i robot czeka w PSecond.")
    except Exception as e:
        print(f"Wystąpił błąd: {e}")

if __name__ == '__main__':
    run_client()