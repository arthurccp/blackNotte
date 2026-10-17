# blackNotte

Um refinador de ideias por voz: um espaço para pensar em voz alta, desenvolver pensamentos com perguntas e transformá-los em notas claras e próximos passos.

> Conte do seu jeito. Algumas perguntas ajudam a organizar suas ideias e transformar pensamentos soltos em uma nota clara.

## Por que criei este app

O blackNotte nasceu de uma ideia minha e de uma necessidade pessoal: eu tinha ideias que considerava brilhantes em lugares e momentos em que nem sempre podia parar para anotar. Queria conseguir registrá-las antes que se perdessem, sem precisar organizar tudo na cabeça primeiro.

Desenvolvi o app para poder falar do meu jeito e, por meio de algumas perguntas, dar forma ao pensamento. A proposta é preservar aquela ideia inicial e ajudar a entender o que ela pode se tornar.

## Proposta

O blackNotte funciona como um parceiro de raciocínio por voz. Você começa com um pensamento, uma dúvida ou uma ideia ainda incompleta. A IA faz perguntas para esclarecer os detalhes e transformar a conversa em uma anotação organizada.

A proposta ampliada é funcionar como um segundo cérebro digital, com três momentos: capturar pensamentos, explorar possibilidades e desenvolver a mesma ideia ao longo do tempo. Uma anotação pode evoluir para um conceito estruturado ou um projeto.

A implementação atual permite refinar uma ideia na conversa ativa e editar as notas salvas. A retomada contextual de conversas após reiniciar o app ainda faz parte da evolução prevista.

## Recursos atuais

- **Captura por voz:** reconhecimento de fala em português brasileiro.
- **Construção por conversa:** perguntas curtas para desenvolver a ideia antes de finalizar.
- **Finalização estruturada:** prepara um resumo para a biblioteca, persistido somente ao tocar em Salvar, e um detalhamento separado em “Sua ideia ganhou forma”, com objetivo e elementos-chave. O campo de escrita e as orientações anteriores são preservados.
- **Salvamento manual:** a nota só é criada quando você toca em **Salvar em Notas**, com o título do tema e exatamente o texto da orientação exibida.
- **Orientações na mesma nota:** ao voltar à captura, continuar a conversa e salvar outra orientação, o texto é acrescentado abaixo do conteúdo existente, preservando o título e suas edições.
- **Abertura após salvar:** o app direciona para a anotação salva para você continuar escrevendo.
- **Edição do conteúdo gerado:** tanto o texto da anotação quanto o detalhamento “Sua ideia ganhou forma” são editáveis, com alterações salvas automaticamente.
- **Nova ideia após finalizar:** ao salvar o resultado final, a conversa é limpa e a captura volta ao estado inicial.
- **Biblioteca de notas:** consulta aos registros ordenados pela última atualização. Deslize a célula para a esquerda para mostrar **Apagar**, ou complete o gesto para excluir.
- **Análise com IA (interface temporariamente oculta):** interpretação da nota com cinco modos de trabalho.
- **Discussão por voz (interface temporariamente oculta):** perguntas sobre uma nota e respostas lidas em voz alta.
- **Persistência local:** armazenamento de notas e análises com SwiftData.

### Modos de análise

| Modo | Objetivo |
| --- | --- |
| Aprofundar | Explorar significados, possibilidades e implicações da ideia. |
| Organizar | Separar ideias misturadas e tornar o pensamento mais claro. |
| Plano | Sugerir poucos passos práticos para tirar a ideia do papel. |
| Questionar | Levantar perguntas, pontos cegos e suposições que merecem revisão. |
| Decidir | Examinar alternativas, critérios e riscos para apoiar uma decisão. |

A análise pode incluir resumo, ideia central, perguntas, riscos, próximos passos e uma distinção entre fatos observados, inferências e questões em aberto.

## Como usar

1. Abra a aba **Capturar** e permita o acesso ao microfone e ao reconhecimento de fala.
2. Toque em **Gravar por voz** e conte sua ideia. Encerre a gravação para enviar sua fala à IA.
3. Confira a orientação. Se quiser guardá-la, toque em **Salvar em Notas**: o app cria a nota e abre a anotação com o texto exibido.
4. Edite o conteúdo ou acrescente suas próprias observações. As alterações são salvas automaticamente.
5. Volte à captura para continuar a mesma conversa. Ao salvar outra orientação, ela será acrescentada ao final da mesma nota, que abrirá novamente.
6. Para concluir, diga “vamos finalizar a ideia” e encerre a gravação. Confira o resumo e o detalhamento preparados pela IA.
7. Toque em **Salvar em Notas** para guardar a finalização. O resumo aparece na biblioteca e o detalhamento fica na seção editável **Sua ideia ganhou forma**. A captura é reiniciada para uma nova ideia.
8. Na aba **Notas**, abra qualquer anotação para editar ou deslize sua célula para a esquerda para apagá-la.

Receber uma orientação ou finalizar a ideia não salva automaticamente. O botão **Salvar em Notas** confirma a inclusão; depois disso, suas edições manuais são salvas automaticamente. As opções de aprofundamento, análise e discussão permanecem temporariamente ocultas.

## Tecnologias

- Swift e SwiftUI para a aplicação e a interface.
- SwiftData para persistência local.
- Speech para reconhecimento de fala.
- AVFoundation para captura de áudio e síntese de voz.
- Integração com a API da OpenAI para construção, análise e discussão das notas.

## Configuração e execução

### Requisitos

- macOS com Xcode e SDK compatíveis com iOS 18.4 ou superior, versão mínima configurada no projeto.
- Simulador compatível ou dispositivo com iOS/iPadOS 18.4 ou superior. Um dispositivo físico é recomendado para experimentar a captura por voz.
- Chave de API da OpenAI e conexão com a internet para os recursos de IA.

### Preparar o projeto

1. Abra `blackNotte.xcodeproj` no Xcode.
2. Copie o arquivo de exemplo para criar a configuração local:

   ```sh
   cp blackNotte/Secrets.plist.example blackNotte/Secrets.plist
   ```

3. Em `Secrets.plist`, preencha `OPENAI_API_KEY` com sua chave. Confira no Xcode se o arquivo pertence ao target do app e é incluído nos recursos do bundle.
4. Ajuste as opções abaixo, se necessário:

   | Chave | Uso | Padrão no código |
   | --- | --- | --- |
   | `OPENAI_API_KEY` | Chave para habilitar as funções de IA | Obrigatória |
   | `OPENAI_MODEL` | Modelo usado nas solicitações | `gpt-5-mini` |
   | `OPENAI_BASE_URL` | Endereço base da API | `https://api.openai.com` |

5. Se for executar em dispositivo físico, configure sua equipe de assinatura em **Signing & Capabilities**.
6. Selecione o destino e execute com **Run** (`⌘R`). Autorize o microfone e o reconhecimento de fala quando solicitado.

O carregamento da configuração prioriza `Secrets.plist` e também aceita os valores pelo `Info.plist`. O arquivo local `Secrets.plist` já está listado no `.gitignore`; não publique sua chave no repositório.

## Dados e escopo atual

As notas e suas análises são armazenadas localmente. Para usar a IA, o app envia o texto relevante à API configurada: o histórico da construção da ideia ou o conteúdo da nota e a pergunta, conforme a operação.

O histórico da conversa e o vínculo com a nota ativa ficam em memória durante a sessão; não são reconstituídos ao reiniciar o aplicativo. As orientações selecionadas são persistidas, mas a transcrição original da fala ainda não possui um campo separado de preservação. Abrir uma nota permite editá-la, sem retomar automaticamente a conversa de refinamento.

O System Prompt central já descreve a proposta ampliada. Os fluxos de construção por voz e discussão ainda utilizam prompts próprios; a integração dessa política entre os fluxos é uma melhoria pendente.

O fluxo atual concentra-se em uma nota por vez. Busca entre notas, conexões automáticas entre ideias, lembretes, sincronização entre dispositivos e memória global de conversas ainda não estão implementados. A interface principal de criação utiliza voz, embora o modelo de dados também preveja notas de origem textual.

## Estrutura do projeto

```text
blackNotte/
├── Agent/          # Instruções da IA e modos de análise
├── Models/         # Notas e análises persistidas
├── Networking/     # Configuração, cliente e contratos da API
├── Services/       # Captura de voz e serviços de IA
├── ViewModels/     # Fluxos de construção, análise e discussão
├── Views/          # Captura, biblioteca e detalhes das notas
└── Assets.xcassets/
```
