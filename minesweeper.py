import urllib.request
import urllib.parse
import json

BASE_EP = "http://localhost:4422/api/"


def get_resource(topic, values):
    data = urllib.parse.urlencode(values)
    url = "{}{}?{}".format(BASE_EP, topic, data)
    with urllib.request.urlopen(url) as resp:
        r = resp.read()
    return json.loads(r)


def login(user, password):
    values = dict(user=user, password=password)
    r = get_resource("login", values)
    token = r["token"]
    tk.token = token
    return token


def start(mines, rows, cols):
    values = dict(token=tk.token, mines=mines, rows=rows, columns=cols)
    r = get_resource("start", values)
    return r["board"]

def select(x,y):
    values = dict(token=tk.token, x=x, y=y)
    r = get_resource("select", values)
    seconds = r["seconds"]
    mines = r["mines"]
    square_value = r["square_value"]
    return (seconds, mines, square_value)

def score():
    values = dict(token=tk.token)
    r = get_resource("score", values)
    seconds = r["seconds"]
    mines = r["mines"]
    return (seconds, mines)

def main():

    print(login("foo","bar"))
    print(start(6,10,10))
    print(select(1,2))
    print(score())


class Token(object):
    token = ""

tk = Token()

if __name__ == "__main__":
    main()

