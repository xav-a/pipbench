class Handler:
    LAMBDA_HEADERS = {
        "openlambda": "handler(conn, event)",
        "openwhisk": "main(args)",
    }

    LAMBDA_NAMES = {
        "openlambda":"lambda_func",
        "openwhisk":"__main__",
    }

    def __init__(self, name, imps, deps, mem, bench):
        self.name = name
        self.imps = imps
        self.deps = deps
        self.mem = mem
        self.bench = bench


    def get_lambda_func(self):
        header = Handler.LAMBDA_HEADERS[self.bench]
        imps = '\n'.join('import %s' % imp for imp in sorted(self.imps))
        simulator = '''import load_simulator
load_simulator.simulate_load(0, {mem})
'''.format(mem=self.mem)
        return '''{imps}
{simulator}
def {header}:
    try:
        return {{'result':"Hello from {name}"}}
    except Exception as e:
        return {{'error': str(e)}}
'''.format(imps=imps, simulator=simulator, header=header, name=self.name)


    def get_packages_txt(self):
        return '\n'.join('{pkg}:{pkg}'.format(pkg=dep) for dep in sorted(self.deps))

    def get_lambda_name(self):
        return Handler.LAMBDA_NAMES[self.bench]
