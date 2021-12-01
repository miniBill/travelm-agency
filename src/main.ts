import fs from "fs";
import path from "path";
import { promisify } from "util";
import {
  Elm,
  GeneratorMode,
  Ports,
  ResponseContent,
  ResponseHandler,
} from "./elm.min.js";

const readFile = (filePath: string) =>
  promisify(fs.readFile)(filePath, { encoding: "utf-8" });

const readDir = promisify(fs.readdir);

const writeFile = async (filePath: string, data: string) => {
  await promisify(fs.mkdir)(path.parse(filePath).dir, { recursive: true });
  await promisify(fs.writeFile)(filePath, data, { encoding: "utf-8" });
};

const getPluginVersion = (): string => {
  const file = path.resolve(__dirname, "..", "package.json");
  const nodeJson = JSON.parse(fs.readFileSync(file, { encoding: "utf-8" }));
  return nodeJson.version;
};

let ports: Ports | undefined;

export const withElmApp = <T>(consumer: (ports: Ports) => T): T => {
  if (!ports) {
    const version = getPluginVersion();
    ({ ports } = Elm.Main.init({ flags: { version } }));
    const throwOnError: ResponseHandler = (response) => {
      if (response.error) {
        throw new Error(response.error);
      }
    };
    ports.sendResponse.subscribe(throwOnError);
  }
  return consumer(ports);
};

export type Options =
  | ({ generatorMode: "inline" } & InlineOptions)
  | ({ generatorMode: "dynamic" } & DynamicOptions);

interface InlineOptions {
  elmPath: string;
  translationDir: string;
}

interface DynamicOptions extends InlineOptions {
  jsonPath: string;
}

export const sendTranslations = (translationDir: string): Promise<string[]> =>
  withElmApp(async (ports) => {
    const translationFileNames = await readDir(translationDir);
    await Promise.all(
      translationFileNames.map(async (fileName) => {
        const fileContent = await readFile(path.join(translationDir, fileName));
        ports.receiveRequest.send({
          type: "translation",
          fileName,
          fileContent,
        });
      })
    );
    return translationFileNames;
  });

export const finishModule = ({
  elmPath,
  generatorMode = null,
}: {
  elmPath: string;
  generatorMode?: GeneratorMode | null;
}): Promise<ResponseContent> =>
  withElmApp(
    async (ports) =>
      new Promise<ResponseContent>((resolve, reject) => {
        const elmModuleName = elmPathToModuleName(elmPath);
        const responseHandler: ResponseHandler = async (res) => {
          ports.sendResponse.unsubscribe(responseHandler);
          if (res.error) {
            reject(res.error);
          }
          if (!res.content) {
            reject(new Error("Received neither error nor content from Elm."));
          } else {
            resolve(res.content);
          }
        };
        ports.sendResponse.subscribe(responseHandler);
        ports.receiveRequest.send({
          type: "finish",
          elmModuleName,
          generatorMode,
        });
      })
  );

export const run = async (options: Options) => {
  const { elmPath, translationDir, generatorMode } = options;
  const [firstTranslationFileName] = await sendTranslations(translationDir);
  if (!firstTranslationFileName) {
    throw new Error("Given translation directory does not contain any files");
  }
  const { elmFile, optimizedJson } = await finishModule({
    elmPath,
    generatorMode,
  });

  const elmPromise = writeFile(elmPath, elmFile);
  let jsonPromises: Promise<void>[] = [];
  if (options.generatorMode === "dynamic") {
    jsonPromises = optimizedJson.map(([jsonFileName, content]) =>
      writeFile(path.join(options.jsonPath, jsonFileName), content)
    );
  }
  await Promise.all([elmPromise, ...jsonPromises]);
};

let elmConfig: { "source-directories": string[] } | undefined;

const elmPathToModuleName = (elmPath: string): string => {
  const absoluteElmPath = path.resolve(elmPath);
  const elmJsonPath = lookForElmJsonRecursively(path.dirname(absoluteElmPath));
  const elmJsonDir = path.dirname(elmJsonPath);
  if (!elmConfig) {
    elmConfig = require(elmJsonPath);
  }
  const elmPathRelativeToElmJson = path.relative(elmJsonDir, absoluteElmPath);
  const possibleSourceDirs = elmConfig!["source-directories"].filter((srcDir) =>
    elmPathRelativeToElmJson.startsWith(srcDir)
  );
  if (possibleSourceDirs.length == 0) {
    throw new Error("Could not determine elm module name");
  }
  if (possibleSourceDirs.length > 1) {
    throw new Error(
      "Multiple matching source directories: " + possibleSourceDirs.join(",")
    );
  }
  return elmPathRelativeToElmJson
    .replace(".elm", "")
    .replace(possibleSourceDirs[0], "")
    .split("/")
    .filter((s) => s)
    .join(".");
};

const lookForElmJsonRecursively = (
  directory: string,
  level: number = 0
): string => {
  const attempt = path.join(directory, "elm.json");
  if (fs.existsSync(attempt)) {
    return attempt;
  }
  // avoid recursing infinitely because of symlinks or something
  if (level > 10) {
    throw new Error(
      "Tried to find elm.json recursively but could not find it."
    );
  }
  return lookForElmJsonRecursively(path.dirname(directory), level + 1);
};
