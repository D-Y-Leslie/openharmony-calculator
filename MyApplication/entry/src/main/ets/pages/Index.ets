// entry/src/main/ets/pages/Index.ets

@Entry
@Component
struct Index {
  // 显示的主文本（当前输入的数字或结果）
  @State mainDisplay: string = '0';
  // 显示的副文本（完整的计算表达式，如 "12 + 50 ="）
  @State subDisplay: string = '';
  // 标记是否刚完成一次计算，用于下一次输入的逻辑判断
  private isFinished: boolean = false;

  // 按钮数据源
  private readonly buttons: string[] = [
    'C', '÷', '×', '⌫',
    '7', '8', '9', '-',
    '4', '5', '6', '+',
    '1', '2', '3', '=',
    '%', '0', '.', ''
  // 注：最后一个空字符串是为了占位，或者可以放 "+/-" 功能，这里留空保持布局
  ];

  build() {
    Column() {
      // --- 显示区域 ---
      Column() {
        // 副显示区：显示过程，例如 "120 × 5"
        Text(this.subDisplay)
          .fontSize(24)
          .fontColor('#a0a0a0') // 浅灰色
          .width('90%')
          .textAlign(TextAlign.End)
          .margin({ top: 30, bottom: 5 })

        // 主显示区：显示结果或当前输入
        Text(this.mainDisplay)
          .fontSize(60)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('90%')
          .textAlign(TextAlign.End)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis }) // 防止数字过长溢出
      }
      .width('100%')
      .height('35%')
      .backgroundColor('#f7f9fc') // 极淡的灰蓝色背景
      .justifyContent(FlexAlign.End)
      .padding({ bottom: 20 })

      // --- 键盘区域 ---
      Grid() {
        ForEach(this.buttons, (item: string) => {
          GridItem() {
            if (item !== '') { // 跳过空占位符
              this.CalculatorButton(item)
            }
          }
          // 让 '=' 号在视觉上更突出，或根据需要调整跨度
          // 这里使用标准网格，逻辑简单清晰
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr') // 4列
      .rowsGap(15)
      .columnsGap(15)
      .padding(20)
      .width('100%')
      .height('65%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 30, topRight: 30 }) // 键盘区域圆角设计
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)' }) // 轻微阴影
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f7f9fc')
  }

  // 自定义按钮组件构建函数
  @Builder
  CalculatorButton(text: string) {
    Button(text)
      .width(75)
      .height(75)
      .type(ButtonType.Circle) // 圆形按钮
      .fontSize(28)
      .fontWeight(FontWeight.Medium)
      .backgroundColor(this.getBtnBackgroundColor(text))
      .fontColor(this.getBtnTextColor(text))
      .shadow(this.getBtnShadow(text))
      .onClick(() => {
        this.handleInput(text);
      })
  }

  // --- 样式逻辑 ---

  getBtnBackgroundColor(text: string): ResourceColor {
    if (text === '=') return '#4a90e2'; // 蓝色强调
    if (['C', '⌫', '%'].includes(text)) return '#dce0e5'; // 浅灰功能键
    if (['÷', '×', '-', '+'].includes(text)) return '#ff9f0a'; // 橙色运算符
    return '#ffffff'; // 白色数字键
  }

  getBtnTextColor(text: string): ResourceColor {
    if (text === '=') return Color.White;
    if (['÷', '×', '-', '+'].includes(text)) return Color.White;
    if (['C', '⌫', '%'].includes(text)) return '#333333';
    return '#333333';
  }

  getBtnShadow(text: string): ShadowOptions {
    // 给白色按钮加一点浮起的效果
    if (!['=', '÷', '×', '-', '+', 'C', '⌫', '%'].includes(text)) {
      return { radius: 5, color: 'rgba(0,0,0,0.1)', offsetY: 2 };
    }
    return { radius: 0, color: Color.Transparent };
  }

  // --- 核心业务逻辑 ---

  handleInput(value: string) {
    // 1. 清除逻辑
    if (value === 'C') {
      this.mainDisplay = '0';
      this.subDisplay = '';
      this.isFinished = false;
      return;
    }

    // 2. 删除逻辑
    if (value === '⌫') {
      if (this.isFinished) {
        this.mainDisplay = '0';
        this.isFinished = false;
        return;
      }
      if (this.mainDisplay.length > 1) {
        this.mainDisplay = this.mainDisplay.slice(0, -1);
      } else {
        this.mainDisplay = '0';
      }
      return;
    }

    // 3. 计算结果逻辑 (=)
    if (value === '=') {
      if (this.subDisplay === '' && !this.isOperator(this.mainDisplay)) {
        return; // 没有表达式，不做操作
      }
      this.calculateResult();
      return;
    }

    // 4. 百分比逻辑 (%)
    if (value === '%') {
      let currentVal = parseFloat(this.mainDisplay);
      this.mainDisplay = (currentVal / 100).toString();
      return;
    }

    // 5. 运算符逻辑 (+ - × ÷)
    if (this.isOperator(value)) {
      this.isFinished = false;

      // 如果当前主显示区已经是运算符，且用户又按了别的运算符，则替换（例如按错键）
      // 注意：这里简化逻辑，假设用户先输入数字再输入运算符

      // 构建表达式： 将 "数字" 移入副显示区
      if (this.subDisplay === '' || this.subDisplay.includes('=')) {
        this.subDisplay = this.mainDisplay + ' ' + value;
      } else {
        // 如果副显示区已有内容，说明在连续计算，比如 1+2+3
        // 先把之前的算出来
        this.calculateResult(false);
        this.subDisplay = this.mainDisplay + ' ' + value;
      }

      // 重置主显示区等待下一个数字输入
      this.mainDisplay = '0';
      return;
    }

    // 6. 数字和小数点逻辑
    // 如果上一步刚计算完，用户直接输数字，则重置所有
    if (this.isFinished) {
      this.mainDisplay = value === '.' ? '0.' : value;
      this.subDisplay = '';
      this.isFinished = false;
      return;
    }

    // 防止多个小数点
    if (value === '.' && this.mainDisplay.includes('.')) {
      return;
    }

    // 普通数字输入
    if (this.mainDisplay === '0' && value !== '.') {
      this.mainDisplay = value;
    } else {
      this.mainDisplay += value;
    }
  }

  // 计算核心函数
  calculateResult(showEquals: boolean = true) {
    try {
      // 提取副显示区的数字和运算符 (例如 "12 +")
      let parts = this.subDisplay.split(' ');
      if (parts.length < 2) return;

      let prevNum = parseFloat(parts[0]);
      let operator = parts[1];
      let currentNum = parseFloat(this.mainDisplay);
      let result = 0;

      // 执行数学运算
      switch (operator) {
        case '+': result = prevNum + currentNum; break;
        case '-': result = prevNum - currentNum; break;
        case '×': result = prevNum * currentNum; break; // 逻辑乘
        case '÷':
          if (currentNum === 0) {
            this.mainDisplay = "Error";
            this.isFinished = true;
            return;
          }
          result = prevNum / currentNum;
          break;
      }

      // 处理精度问题 (例如 0.1 + 0.2) 并去除尾部零
      let finalResult = parseFloat(result.toFixed(8)).toString();

      if (showEquals) {
        this.subDisplay = `${prevNum} ${operator} ${currentNum} =`;
        this.mainDisplay = finalResult;
        this.isFinished = true;
      } else {
        // 连续计算模式，只更新结果用于下一次计算
        this.mainDisplay = finalResult;
      }

    } catch (e) {
      this.mainDisplay = 'Error';
      this.isFinished = true;
    }
  }

  // 辅助判断是否为运算符
  isOperator(val: string): boolean {
    return ['+', '-', '×', '÷'].includes(val);
  }
}