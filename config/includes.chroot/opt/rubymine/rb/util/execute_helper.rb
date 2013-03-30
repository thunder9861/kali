#
# Copyright 2000-2009 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module ExecuteHelper
    import com.intellij.openapi.command.CommandProcessor unless defined? CommandProcessor
    import com.intellij.util.ActionRunner unless defined? ActionRunner
    import java.lang.Runnable unless defined? Runnable
    import com.intellij.openapi.application.ApplicationManager unless defined? ApplicationManager

    def self.run_as_command(project, command_name, &proc)
        runnable = Runnable.impl { proc.call }
        CommandProcessor.instance.executeCommand project, runnable, command_name, nil
    end

    def self.run_in_write_action(&proc)
        ActionRunner.runInsideWriteAction(ActionRunner::InterruptibleRunnable.impl { proc.call })
    end

    def self.run_in_edt(&proc)
        ApplicationManager.get_application.invoke_later { proc.call }
    end

    def self.run_as_command_in_write_action(project, command_name, &proc)
        ref = nil
        run_as_command(project, command_name) do
            run_in_write_action do
                ref = proc.call
            end
        end
        ref
    end

    def self.run_as_command_in_write_action_with_formatting(project, command_name, &proc)
        run_as_command(project, command_name) do
          com.intellij.psi.impl.source.PostprocessReformattingAspect.getInstance(project).postponeFormattingInside do
            run_in_write_action do
                proc.call
            end
          end
        end
    end
end