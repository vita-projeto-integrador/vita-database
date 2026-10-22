-- Exported from QuickDBD: https://www.quickdatabasediagrams.com/
-- Ponskan / Vita - modelo de dados (versao MySQL)

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- Tabelas
-- ---------------------------------------------------------------------------

CREATE TABLE `usuarios` (
    `id` CHAR(36)  NOT NULL DEFAULT (UUID()),
    `nome` VARCHAR(255)  NOT NULL,
    `email` VARCHAR(255)  NOT NULL,
    `senha` VARCHAR(255)  NOT NULL,
    `telefone` VARCHAR(255)  NULL,
    `data_nascimento` DATETIME  NULL,
    `tipo_acesso` ENUM('produtor', 'estudante')  NOT NULL DEFAULT 'produtor',
    `endereco` VARCHAR(255)  NULL,
    `cnpj` VARCHAR(255)  NULL,
    `faculdade` VARCHAR(255)  NULL,
    `curso` VARCHAR(255)  NULL,
    `createdAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deletedAt` DATETIME  NULL,
    CONSTRAINT `pk_usuarios` PRIMARY KEY (
        `id`
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `analises` (
    `id` CHAR(36)  NOT NULL DEFAULT (UUID()),
    `id_usuario` CHAR(36)  NOT NULL,
    `status` ENUM('finalizada', 'pendente', 'cancelada')  NOT NULL DEFAULT 'pendente',
    `createdAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deletedAt` DATETIME  NULL,
    CONSTRAINT `pk_analises` PRIMARY KEY (
        `id`
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `imagens` (
    `id` CHAR(36)  NOT NULL DEFAULT (UUID()),
    `id_analise` CHAR(36)  NOT NULL,
    `nome` VARCHAR(255)  NOT NULL,
    `caminho` VARCHAR(255)  NOT NULL,
    -- SRID 4326 no MySQL usa ordem (latitude, longitude) por padrao.
    -- Para gravar em lon,lat: ST_GeomFromText('POINT(lon lat)', 4326, 'axis-order=long-lat')
    `coordenadas` POINT SRID 4326  NULL,
    `tipo_mime` ENUM('image/jpeg', 'image/jpg', 'image/png', 'image/webp')  NOT NULL,
    `tamanho` INT  NOT NULL,
    `createdAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deletedAt` DATETIME  NULL,
    CONSTRAINT `pk_imagens` PRIMARY KEY (
        `id`
    ),
    CONSTRAINT `ck_imagens_tamanho` CHECK (`tamanho` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `processadas` (
    `id` CHAR(36)  NOT NULL DEFAULT (UUID()),
    `id_imagem` CHAR(36)  NOT NULL,
    `nome` VARCHAR(255)  NOT NULL,
    `caminho` VARCHAR(255)  NOT NULL,
    `tipo_mime` ENUM('image/jpeg', 'image/jpg', 'image/png', 'image/webp')  NOT NULL,
    `tamanho` INT  NOT NULL,
    `createdAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deletedAt` DATETIME  NULL,
    CONSTRAINT `pk_processadas` PRIMARY KEY (
        `id`
    ),
    CONSTRAINT `ck_processadas_tamanho` CHECK (`tamanho` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `classificacoes` (
    `id` CHAR(36)  NOT NULL DEFAULT (UUID()),
    `id_analise` CHAR(36)  NOT NULL,
    -- milissegundos (arredondado no worker)
    `tempo_execucao` INT  NULL,
    `classe` INT  NOT NULL,
    `confianca` DOUBLE  NOT NULL,
    `modelo_cnn` VARCHAR(255)  NOT NULL,
    `createdAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deletedAt` DATETIME  NULL,
    CONSTRAINT `pk_classificacoes` PRIMARY KEY (
        `id`
    ),
    -- relacao 1-1 com analises
    CONSTRAINT `uc_classificacoes_id_analise` UNIQUE (
        `id_analise`
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------------
-- Indices
-- ---------------------------------------------------------------------------

-- E-mail unico apenas entre usuarios ativos.
-- MySQL nao tem indice parcial (WHERE). O indice funcional abaixo indexa o e-mail
-- so quando deletedAt IS NULL; nos demais casos indexa NULL, que nao colide.
CREATE UNIQUE INDEX `ux_usuarios_email_ativos` ON `usuarios` (
    (CASE WHEN `deletedAt` IS NULL THEN `email` END)
);

-- listagem de analises por usuario, mais recentes primeiro
-- (tambem atende a FK id_usuario, dispensando o indice automatico do InnoDB)
CREATE INDEX `ix_analises_id_usuario_createdAt` ON `analises` (`id_usuario`, `createdAt` DESC);

-- Consultas espaciais (mapa / bounding box / raio).
-- MySQL so aceita SPATIAL INDEX em coluna NOT NULL; com `coordenadas` NULL, o indice
-- falha. Habilitar apenas se a coluna passar a ser obrigatoria:
-- ALTER TABLE `imagens` MODIFY `coordenadas` POINT SRID 4326 NOT NULL;
-- CREATE SPATIAL INDEX `ix_imagens_coordenadas` ON `imagens` (`coordenadas`);

-- ---------------------------------------------------------------------------
-- Chaves estrangeiras (o InnoDB cria indice para cada FK automaticamente)
-- ---------------------------------------------------------------------------

ALTER TABLE `analises` ADD CONSTRAINT `fk_analises_id_usuario` FOREIGN KEY(`id_usuario`)
REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

ALTER TABLE `imagens` ADD CONSTRAINT `fk_imagens_id_analise` FOREIGN KEY(`id_analise`)
REFERENCES `analises` (`id`) ON DELETE CASCADE;

ALTER TABLE `processadas` ADD CONSTRAINT `fk_processadas_id_imagem` FOREIGN KEY(`id_imagem`)
REFERENCES `imagens` (`id`) ON DELETE CASCADE;

ALTER TABLE `classificacoes` ADD CONSTRAINT `fk_classificacoes_id_analise` FOREIGN KEY(`id_analise`)
REFERENCES `analises` (`id`) ON DELETE CASCADE;