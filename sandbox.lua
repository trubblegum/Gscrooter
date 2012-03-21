io = {stdin = io.stdin, stdout = io.stdout, stderr = io.stderr}
os = {time = os.time}
dofile = nil
loadfile = nil
debug = nil
package.loaders = {package.loaders[1], package.loaders[2], package.loaders[3]}
package.loadlib = nil
package.loaded.debug = nil
package.loaded.io = nil
package.loaded.os = os